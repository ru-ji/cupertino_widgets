import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeTextField]: placeholder + onChanged, a password
/// field, an email keyboard, and a controller-driven field with a clear button
/// and a max length.
class TextFieldDemo extends StatefulWidget {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _controller = TextEditingController(text: 'Editable');
  String _typed = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Native Text Fields'),
          const SizedBox(height: 8),
          CupertinoNativeTextField(
            placeholder: 'Type something…',
            clearButtonMode: CupertinoNativeClearButtonMode.whileEditing,
            textInputAction: TextInputAction.done,
            onChanged: (v) => setState(() => _typed = v),
            onSubmitted: (v) => debugPrint('submitted: $v'),
          ),
          const SizedBox(height: 4),
          Text('You typed: $_typed'),
          const SizedBox(height: 12),
          const CupertinoNativeTextField(
            placeholder: 'Password',
            obscureText: true,
            textContentType: 'password',
          ),
          const SizedBox(height: 12),
          const CupertinoNativeTextField(
            placeholder: 'Email',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            textContentType: 'emailAddress',
          ),
          const SizedBox(height: 12),
          CupertinoNativeTextField(
            controller: _controller,
            maxLength: 20,
            textAlign: TextAlign.center,
            clearButtonMode: CupertinoNativeClearButtonMode.always,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            cursorColor: Colors.purple,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: () => _controller.text = 'Set from Flutter',
                child: const Text('Set text'),
              ),
              TextButton(
                onPressed: () => _controller.clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
