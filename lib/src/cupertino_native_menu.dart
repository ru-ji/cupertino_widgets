import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'models/cupertino_native_menu_item.dart';
import 'models/cupertino_native_button_style.dart';

class CupertinoNativeMenu extends StatefulWidget {
  final String title;
  final String? systemImage;
  final CupertinoNativeButtonStyle style;
  final Color? color;
  final TextStyle? textStyle;
  final List<CupertinoNativeMenuItem> items;
  final Function(String, dynamic)? onAction;
  final double? width;
  final double? height;

  const CupertinoNativeMenu({
    super.key,
    required this.items,
    this.title = 'Options',
    this.systemImage,
    this.style = CupertinoNativeButtonStyle.automatic,
    this.color,
    this.textStyle,
    this.onAction,
    this.width,
    this.height,
  });

  @override
  State<CupertinoNativeMenu> createState() => _CupertinoNativeMenuState();
}

class _CupertinoNativeMenuState extends State<CupertinoNativeMenu> {
  MethodChannel? _channel;
  double? _intrinsicWidth;
  double? _intrinsicHeight;

  @override
  void didUpdateWidget(covariant CupertinoNativeMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.title != widget.title ||
        oldWidget.systemImage != widget.systemImage ||
        oldWidget.style != widget.style ||
        oldWidget.color != widget.color ||
        oldWidget.textStyle != widget.textStyle) {
      _updateMenu();
    }
  }

  void _updateMenu() {
    _channel?.invokeMethod('updateMenu', _toMap()).then((_) {
      _requestIntrinsicSize();
    });
  }

  Future<void> _requestIntrinsicSize() async {
    if (_channel == null) return;
    try {
      final result = await _channel!.invokeMethod<Map>('getIntrinsicSize');
      if (result != null && mounted) {
        final w = (result['width'] as num?)?.toDouble();
        final h = (result['height'] as num?)?.toDouble();
        if (w != null && h != null && w > 0 && h > 0) {
          setState(() {
            _intrinsicWidth = w;
            _intrinsicHeight = h;
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'title': widget.title,
      'systemImage': widget.systemImage,
      'items': widget.items.map((e) => e.toMap()).toList(),
      'style': widget.style.name,
      // ignore: deprecated_member_use
      'color': widget.color?.value,
      'fontSize': widget.textStyle?.fontSize,
      'fontWeight': widget.textStyle?.fontWeight?.index,
      // ignore: deprecated_member_use
      'textColor': widget.textStyle?.color?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/menu_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
    await Future.delayed(const Duration(milliseconds: 50));
    _requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onAction') {
      final String id = call.arguments['id'];
      final dynamic value = call.arguments['value'];
      widget.onAction?.call(id, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final platformView = UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_menu',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      // If explicit width/height provided, use them
      if (widget.width != null || widget.height != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: platformView,
        );
      }

      // Use intrinsic size from native view, with defaults until size is received
      // Default: 100x44 for menu button
      return SizedBox(
        width: _intrinsicWidth ?? 100,
        height: _intrinsicHeight ?? 44,
        child: platformView,
      );
    }

    return SizedBox(
      height: widget.height ?? 44,
      width: widget.width ?? 100,
      child: const Center(child: Text("iOS Only")),
    );
  }
}
