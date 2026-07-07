import 'package:flutter/material.dart';

import 'pages/native_list_form_demo_page.dart';
import 'pages/native_scaffold_demo_page.dart';
import 'pages/native_searchable_demo_page.dart';
import 'pages/standalone_tab_bar_demo_page.dart';
import 'widgets/demos/alert_demo.dart';
import 'widgets/demos/button_demo.dart';
import 'widgets/demos/menu_demo.dart';
import 'widgets/demos/progress_demo.dart';
import 'widgets/demos/segmented_control_demo.dart';
import 'widgets/demos/slider_demo.dart';
import 'widgets/demos/text_field_demo.dart';
import 'widgets/demos/toggle_demo.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lastAction = 'None';
  bool _isMapEnabled = false;
  double _sliderValue = 0.5;
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleBrightness() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _onAction(String action) {
    setState(() => _lastAction = action);
  }

  void _onMapEnabledChanged(bool value) {
    setState(() => _isMapEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Native CupertinoNative Menu'),
              actions: [
                // Toggle the APP's brightness: every native component
                // (text field, scaffold, list/form, tab bar) follows it live.
                IconButton(
                  tooltip: 'Toggle brightness',
                  icon: Icon(_themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: _toggleBrightness,
                ),
              ],
            ),
            // Tap-outside-to-dismiss for the native text fields: a real tap
            // anywhere on the page unfocuses (the FocusNode bridge then
            // resigns the native first responder, closing the keyboard).
            // Unlike TapRegion/onTapOutside this does NOT trigger on
            // scroll-start, because onTap only fires for completed taps.
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Last Action: $_lastAction'),
                    ToggleDemo(
                      isMapEnabled: _isMapEnabled,
                      onMapEnabledChanged: _onMapEnabledChanged,
                      onAction: _onAction,
                    ),
                    SegmentedControlDemo(onAction: _onAction),
                    SliderDemo(
                      value: _sliderValue,
                      onChanged: (v) => setState(() => _sliderValue = v),
                    ),

                    MenuDemo(
                      isMapEnabled: _isMapEnabled,
                      onMapEnabledChanged: _onMapEnabledChanged,
                      onAction: _onAction,
                    ),
                    AlertDemo(onAction: _onAction),
                    const Divider(height: 40),
                    const ProgressDemo(),
                    const Divider(height: 40),
                    ButtonDemo(onAction: _onAction),
                    const TextField(
                      decoration: InputDecoration(labelText: 'TextField'),
                    ),
                    const Divider(height: 40),
                    const TextFieldDemo(),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StandaloneTabBarDemoPage(),
                          ),
                        );
                      },
                      child: const Text('Standalone TabBar'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NativeScaffoldDemoPage(),
                          ),
                        );
                      },
                      child: const Text('Native Scaffold'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NativeSearchableDemoPage(),
                          ),
                        );
                      },
                      child: const Text('Native Searchable'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NativeListFormDemoPage(),
                          ),
                        );
                      },
                      child: const Text('Native List & Form'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
