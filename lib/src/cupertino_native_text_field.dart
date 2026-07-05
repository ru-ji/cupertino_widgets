import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/native_platform_view_mixin.dart';

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

  /// Explicit size. When null, the field fills the available width and uses its
  /// intrinsic height.
  final double? width;
  final double? height;

  const CupertinoNativeTextField({
    super.key,
    this.controller,
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
    this.width,
    this.height,
  });

  @override
  State<CupertinoNativeTextField> createState() =>
      _CupertinoNativeTextFieldState();
}

class _CupertinoNativeTextFieldState extends State<CupertinoNativeTextField>
    with NativePlatformViewStateMixin {
  /// The text native currently holds — used to break the controller<->native
  /// sync feedback loop.
  String _lastNativeText = '';

  @override
  void initState() {
    super.initState();
    _lastNativeText = widget.controller?.text ?? '';
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CupertinoNativeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _lastNativeText = widget.controller?.text ?? '';
    }
    if (_configChanged(oldWidget)) {
      updateNativeView('updateTextField', _toMap());
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
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
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      if (widget.width != null || widget.height != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height ?? intrinsicHeight ?? 36,
          child: platformView,
        );
      }

      // Fill available width (like Flutter's TextField); intrinsic height.
      return LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
          return SizedBox(
            width: width,
            height: intrinsicHeight ?? 36,
            child: platformView,
          );
        },
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
