import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CupertinoNativeAlertAction {
  final String title;
  final bool isDestructive;
  final bool isCancel;
  final VoidCallback? onPressed;

  const CupertinoNativeAlertAction({
    required this.title,
    this.isDestructive = false,
    this.isCancel = false,
    this.onPressed,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDestructive': isDestructive,
      'isCancel': isCancel,
    };
  }
}

class CupertinoNativeAlert {
  static const MethodChannel _channel = MethodChannel(
    'com.example.flutter_cupertino/alert',
  );

  static Future<void> show({
    required String title,
    String? message,
    required List<CupertinoNativeAlertAction> actions,
  }) async {
    try {
      final int? index = await _channel.invokeMethod<int>('showAlert', {
        'title': title,
        'message': message,
        'actions': actions.map((a) => a.toMap()).toList(),
      });

      if (index != null && index >= 0 && index < actions.length) {
        actions[index].onPressed?.call();
      }
    } on PlatformException catch (e) {
      // Handle error or print
      debugPrint("Failed to show alert: ${e.message}");
    }
  }
}
