import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/native_platform_view_mixin.dart';

/// Disambiguates a quick drag (scroll the ancestor `Scrollable`, like a plain
/// Flutter `TextField` allows) from a press-and-hold (enter native text
/// selection, with its handles/magnifier) on the same touch that starts on
/// the field.
///
/// A blanket-eager recognizer would let selection-dragging work but also
/// swallow every scroll attempt that starts on top of the field. This instead
/// waits briefly: if the pointer moves past a small slop before the hold
/// timeout, it rejects so an ancestor scroll recognizer can claim the
/// gesture; if the pointer stays roughly still past the timeout (or is
/// released quickly, as a plain tap), it accepts so the native `UITextField`
/// gets the full gesture (selection, handle-dragging, or tap-to-focus/caret).
class _NativeTextFieldGestureRecognizer extends OneSequenceGestureRecognizer {
  static const Duration _holdTimeout = Duration(milliseconds: 300);
  static const double _slop = 12.0;

  Offset? _downPosition;
  Timer? _timer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _downPosition = event.position;
    _timer = Timer(_holdTimeout, () => resolve(GestureDisposition.accepted));
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final start = _downPosition;
      if (start != null && (event.position - start).distance > _slop) {
        _timer?.cancel();
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerUpEvent) {
      _timer?.cancel();
      // Released quickly without much movement: a plain tap, let it through
      // so focus/caret placement still reaches the native field.
      resolve(GestureDisposition.accepted);
    } else if (event is PointerCancelEvent) {
      _timer?.cancel();
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _timer?.cancel();
  }

  @override
  void rejectGesture(int pointer) {
    _timer?.cancel();
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _timer?.cancel();
    _downPosition = null;
  }

  @override
  String get debugDescription => 'CupertinoNativeTextField selection gesture';
}

/// When the built-in clear (×) button appears in a [CupertinoNativeTextField].
/// Mirrors UIKit's `UITextField.ViewMode`.
enum CupertinoNativeClearButtonMode { never, whileEditing, unlessEditing, always }

/// A native single-line iOS text field backed by `UITextField`, exposing
/// customization comparable to Flutter's [TextField]/`CupertinoTextField`.
///
/// Provide a [controller] for two-way text sync, or just use [onChanged]. The
/// field fills the available width by default (like Flutter's `TextField`);
/// pass [width]/[height] to size it explicitly.
///
/// iOS only — a plain Flutter [EditableText]-free fallback renders elsewhere.
/// Multi-line input (via `UITextView`) is not covered yet.
class CupertinoNativeTextField extends StatefulWidget {
  final TextEditingController? controller;

  /// An optional Flutter [FocusNode]. It is bridged to the native field's
  /// first-responder state: focusing/unfocusing the node shows/hides the
  /// keyboard, and tapping the field focuses the node. Because of this bridge,
  /// `FocusScope.of(context).unfocus()` dismisses the native keyboard. When
  /// null, an internal node is created so `unfocus()` still works.
  final FocusNode? focusNode;
  final String? placeholder;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  /// Text style. `fontSize`, `fontWeight`, and `color` are forwarded natively.
  final TextStyle? style;
  final Color? cursorColor;
  final CupertinoNativeClearButtonMode clearButtonMode;

  /// iOS autofill/content type hint (e.g. `'password'`, `'username'`,
  /// `'emailAddress'`, `'oneTimeCode'`, `'name'`, `'telephoneNumber'`,
  /// `'fullStreetAddress'`, `'URL'`). Passed through to `UITextContentType`.
  final String? textContentType;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  /// Called when the field gains focus (e.g. the user taps it).
  final VoidCallback? onTap;

  /// Called when a pointer taps outside the field. A common use is dismissing
  /// the keyboard: `onTapOutside: (_) => FocusScope.of(context).unfocus()`.
  final TapRegionCallback? onTapOutside;

  /// Explicit size. When null, the field fills the available width and uses its
  /// intrinsic height.
  final double? width;
  final double? height;

  const CupertinoNativeTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.style,
    this.cursorColor,
    this.clearButtonMode = CupertinoNativeClearButtonMode.never,
    this.textContentType,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    this.width,
    this.height,
  });

  @override
  State<CupertinoNativeTextField> createState() =>
      _CupertinoNativeTextFieldState();
}

class _CupertinoNativeTextFieldState extends State<CupertinoNativeTextField>
    with NativePlatformViewStateMixin, WidgetsBindingObserver {
  /// Claims a press-and-hold for native text selection while ceding a quick
  /// drag to an ancestor `Scrollable` — see
  /// [_NativeTextFieldGestureRecognizer].
  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(_NativeTextFieldGestureRecognizer.new),
  };

  /// The text native currently holds — used to break the controller<->native
  /// sync feedback loop.
  String _lastNativeText = '';

  /// The effective focus node: the caller's, or an internal one so that
  /// `FocusScope.unfocus()` and `onTapOutside` dismissal still work.
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _lastNativeText = widget.controller?.text ?? '';
    widget.controller?.addListener(_onControllerChanged);
    _focusNode = widget.focusNode ?? _createInternalFocusNode();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Bottom view inset (physical px) seen at the previous metrics tick, to
  /// detect whether the keyboard is currently rising.
  double _lastBottomInset = 0;

  /// Keyboard insets changed. iOS reports this repeatedly while the keyboard
  /// animates (not just once at the end) — reacting on each *rising* tick with
  /// an instant minimal jump tracks the keyboard's real motion progressively.
  /// Falling/settled insets are deliberately ignored so keyboard dismissal and
  /// post-settle blips (autocorrect bar, emoji switch) never move the scroll.
  @override
  void didChangeMetrics() {
    final view =
        WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return;
    final bottomInset = view.viewInsets.bottom;
    final rising = bottomInset > _lastBottomInset;
    _lastBottomInset = bottomInset;
    if (rising && _focusNode.hasFocus) _revealAboveKeyboard();
  }

  /// Scrolls the minimum needed to keep the field above the keyboard.
  /// `keepVisibleAtEnd` only ever scrolls when the field sits beyond the
  /// bottom edge of the (keyboard-shrunken) viewport — when the field is
  /// already visible it is a strict no-op, so this never repositions or
  /// fights a scroll the user did themselves. The jump is instant
  /// (`duration` zero, Flutter's default): each metrics tick already reflects
  /// the keyboard's current height, so animating would lag the next tick.
  void _revealAboveKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  FocusNode _createInternalFocusNode() {
    _ownsFocusNode = true;
    return FocusNode(debugLabel: 'CupertinoNativeTextField');
  }

  @override
  void didUpdateWidget(covariant CupertinoNativeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _lastNativeText = widget.controller?.text ?? '';
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode) {
        _focusNode.dispose();
        _ownsFocusNode = false;
      }
      _focusNode = widget.focusNode ?? _createInternalFocusNode();
    }
    if (_configChanged(oldWidget)) {
      updateNativeView('updateTextField', _toMap());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_onControllerChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// Flutter focus changed (e.g. `FocusScope.unfocus()`); mirror it to the
  /// native first responder. Native responder ops are idempotent, so this
  /// won't loop with the native `onFocusChange` callback.
  void _onFlutterFocusChange(bool hasFocus) {
    channel?.invokeMethod(hasFocus ? 'focus' : 'unfocus');
  }

  bool _configChanged(CupertinoNativeTextField o) {
    return o.placeholder != widget.placeholder ||
        o.keyboardType != widget.keyboardType ||
        o.textInputAction != widget.textInputAction ||
        o.obscureText != widget.obscureText ||
        o.autocorrect != widget.autocorrect ||
        o.enableSuggestions != widget.enableSuggestions ||
        o.textCapitalization != widget.textCapitalization ||
        o.textAlign != widget.textAlign ||
        o.maxLength != widget.maxLength ||
        o.enabled != widget.enabled ||
        o.readOnly != widget.readOnly ||
        o.style != widget.style ||
        o.cursorColor != widget.cursorColor ||
        o.clearButtonMode != widget.clearButtonMode ||
        o.textContentType != widget.textContentType;
  }

  /// Push programmatic controller edits to native (guarded against the echo
  /// that native change notifications would otherwise cause).
  void _onControllerChanged() {
    final text = widget.controller?.text ?? '';
    if (text != _lastNativeText) {
      _lastNativeText = text;
      channel?.invokeMethod('setText', {'text': text});
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'text': widget.controller?.text ?? '',
      'placeholder': widget.placeholder,
      'keyboardType': _keyboardTypeName(widget.keyboardType),
      'textInputAction': widget.textInputAction?.name,
      'obscureText': widget.obscureText,
      'autocorrect': widget.autocorrect,
      'enableSuggestions': widget.enableSuggestions,
      'textCapitalization': widget.textCapitalization.name,
      'textAlign': widget.textAlign.name,
      'maxLength': widget.maxLength,
      'enabled': widget.enabled,
      'readOnly': widget.readOnly,
      'autofocus': widget.autofocus,
      'fontSize': widget.style?.fontSize,
      'fontWeight': widget.style?.fontWeight?.index,
      'textColor': widget.style?.color?.toARGB32(),
      'cursorColor': widget.cursorColor?.toARGB32(),
      'clearButtonMode': widget.clearButtonMode.name,
      'textContentType': widget.textContentType,
    };
  }

  static String _keyboardTypeName(TextInputType type) {
    // TextInputType isn't an enum; its JSON name is like "TextInputType.email".
    final name = type.toJson()['name'];
    if (name is String) return name.split('.').last;
    return 'text';
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(
      id,
      'flutter_cupertino/textfield_$id',
      onMethodCall: _handleMethodCall,
    );
    await Future.delayed(const Duration(milliseconds: 50));
    requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onChanged':
        final text = (call.arguments['text'] as String?) ?? '';
        _lastNativeText = text;
        final controller = widget.controller;
        if (controller != null && controller.text != text) {
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        widget.onChanged?.call(text);
        break;
      case 'onSubmitted':
        widget.onSubmitted?.call((call.arguments['text'] as String?) ?? '');
        break;
      case 'onEditingComplete':
        widget.onEditingComplete?.call();
        break;
      case 'onFocusChange':
        final focused = (call.arguments['focused'] as bool?) ?? false;
        if (focused) {
          if (!_focusNode.hasFocus) _focusNode.requestFocus();
          widget.onTap?.call();
          _revealAboveKeyboard();
        } else if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final platformView = UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_text_field',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: _gestureRecognizers,
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      final Widget sized;
      if (widget.width != null || widget.height != null) {
        sized = SizedBox(
          width: widget.width,
          height: widget.height ?? intrinsicHeight ?? 52,
          child: platformView,
        );
      } else {
        // Fill available width (like Flutter's TextField); intrinsic height.
        sized = LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
            return SizedBox(
              width: width,
              height: intrinsicHeight ?? 52,
              child: platformView,
            );
          },
        );
      }

      Widget content = sized;
      if (widget.onTapOutside != null) {
        content = TapRegion(onTapOutside: widget.onTapOutside, child: content);
      }
      // Host the focus node so `FocusScope.unfocus()` reaches the native field.
      return Focus(
        focusNode: _focusNode,
        onFocusChange: _onFlutterFocusChange,
        child: content,
      );
    }

    // Fallback for non-iOS: a plain Flutter EditableText-less placeholder.
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 36,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.controller?.text.isNotEmpty == true
              ? widget.controller!.text
              : (widget.placeholder ?? ''),
        ),
      ),
    );
  }
}
