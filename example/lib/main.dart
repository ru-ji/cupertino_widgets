import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lastAction = 'None';
  bool _isMapEnabled = false;
  double _sliderValue = 0.5;
  String _tabSelection = 'home';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native CupertinoNative Menu')),
        bottomNavigationBar: Container(
          height: 80,
          color: Colors.pink,
          child: CupertinoNativeTabView(
            accentColor: Colors.orange,
            tabs: const [
              CupertinoNativeTab(
                title: 'Home',
                systemImage: 'house.fill',
                id: 'home',
              ),
              CupertinoNativeTab(
                title: 'Search',
                systemImage: 'magnifyingglass',
                id: 'search',
              ),
              CupertinoNativeTab(
                title: 'Settings',
                systemImage: 'gear',
                id: 'settings',
              ),
            ],
            initialSelection: _tabSelection,
            onSelectionChanged: (id) {
              setState(() {
                _tabSelection = id;
                _lastAction = "Tab: $id";
              });
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Last Action: $_lastAction'),

              CupertinoNativeToggle(
                value: _isMapEnabled,
                label: "Map Enabled",
                activeColor: Colors.blue,
                onChanged: (v) {
                  setState(() {
                    _isMapEnabled = v;
                    _lastAction = "Toggle: $v";
                  });
                },
              ),
              CupertinoNativeToggle(
                value: !_isMapEnabled,
                //label: "Silent Mode",
                activeColor: Colors.red,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                onChanged: (v) {
                  setState(() {
                    _isMapEnabled = !v; // just flipping the same state for demo
                    _lastAction = "Silent Toggle: $v";
                  });
                },
              ),
              SizedBox(
                width: 300,
                child: CupertinoNativeSegmentedControl(
                  groupValue:
                      0, // Should be stateful in real usage, simplified for static UI example
                  children: const ["Day", "Week", "Month", "Year"],

                  //color: Colors.red,
                  onValueChanged: (v) {
                    setState(() => _lastAction = "Segment: $v");
                  },
                ),
              ),
              Text('Slider Value: ${_sliderValue.toStringAsFixed(2)}'),
              CupertinoNativeSlider(
                value: _sliderValue,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.purple,
                onChanged: (v) {
                  setState(() {
                    _sliderValue = v;
                  });
                },
              ),
              CupertinoNativeMenu(
                title: "Options",
                systemImage: "ellipsis.circle",
                style: CupertinoNativeButtonStyle.glassProminent, // Added style
                color: Colors.purple, // Added color
                textStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                items: [
                  const CupertinoNativeMenuSection(
                    items: [
                      CupertinoNativeMenuAction(
                        title: "Share",
                        systemImage: "square.and.arrow.up",
                        actionId: "share",
                      ),
                      CupertinoNativeMenuAction(
                        title: "Copy",
                        systemImage: "doc.on.doc",
                        actionId: "copy",
                      ),
                    ],
                  ),
                  const CupertinoNativeMenuSection(
                    items: [
                      CupertinoNativeMenuAction(
                        title: "Show Alert",
                        systemImage: "exclamationmark.triangle",
                        actionId: "alert",
                        isDestructive: true,
                      ),
                      CupertinoNativeMenuAction(
                        title: "Delete",
                        systemImage: "trash",
                        isDestructive: true,
                        actionId: "delete",
                      ),
                    ],
                  ),
                  CupertinoNativeSubmenu(
                    title: "View",
                    systemImage: "eye",
                    items: [
                      CupertinoNativeMenuToggle(
                        title: "Show Map",
                        value: _isMapEnabled,
                        actionId: "toggle_map",
                        systemImage: "map",
                      ),
                      const CupertinoNativeMenuAction(
                        title: "Reset View",
                        actionId: "reset_view",
                      ),
                    ],
                  ),
                ],
                onAction: (id, value) {
                  setState(() {
                    if (id == 'toggle_map') {
                      _isMapEnabled = value as bool;
                      _lastAction = 'Map Enabled: $_isMapEnabled';
                    } else {
                      _lastAction = 'Selected: $id';
                    }
                  });
                  debugPrint("Action: $id, Value: $value");
                },
              ),
              ElevatedButton(
                onPressed: () => _showAlert(context),
                child: const Text("Show Native Alert"),
              ),
              const Text("Native Progress"),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoNativeProgressIndicator(
                    style: CupertinoNativeProgressStyle.circular,
                  ),
                  CupertinoNativeProgressIndicator(
                    style: CupertinoNativeProgressStyle.circular,
                    color: Colors.pink,
                  ),
                ],
              ),
              Center(
                child: Container(
                  color: Colors.red,
                  width: 200,
                  child: const CupertinoNativeProgressIndicator(
                    value: 0.5,

                    style: CupertinoNativeProgressStyle.linear,
                    color: Colors.green,
                  ),
                ),
              ),
              Center(
                child: Container(
                  color: Colors.amber,
                  child: const CupertinoNativeProgressIndicator(
                    value: 10,
                    total: 100,
                    style: CupertinoNativeProgressStyle.linear,
                    label: "Downloading...",
                    color: Colors.blue,
                  ),
                ),
              ),
              const Text("Tap the icon above to open the native menu"),
              const Divider(height: 40),
              const Text("Native Buttons"),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Use Expanded to take remaining width in a Row
                  Expanded(
                    child: CupertinoNativeButton(
                      title: "Filled",
                      color: Colors.red,
                      style: CupertinoNativeButtonStyle.filled,
                      controlSize: .large,
                      expand: true,
                      systemImage: "star.fill",
                      onPressed: () =>
                          setState(() => _lastAction = "Filled Button"),
                    ),
                  ),
                  CupertinoNativeButton(
                    title: "Tinted",
                    textStyle: const TextStyle(fontSize: 20),
                    style: CupertinoNativeButtonStyle.tinted,
                    onPressed: () =>
                        setState(() => _lastAction = "Tinted Button"),
                  ),
                  CupertinoNativeButton(
                    title: "Glass",
                    style: CupertinoNativeButtonStyle.glassProminent,
                    color: Colors.purple,
                    onPressed: () =>
                        setState(() => _lastAction = "Glass Button"),
                  ),
                  CupertinoNativeButton(
                    title: "Plain",
                    style: CupertinoNativeButtonStyle.plain,
                    onPressed: () =>
                        setState(() => _lastAction = "Plain Button"),
                  ),
                ],
              ),

              const Text("Control Size & Expand"),
              Column(
                children: [
                  CupertinoNativeButton(
                    title: "Large Expanded",
                    style: CupertinoNativeButtonStyle.filled,
                    controlSize: CupertinoNativeControlSize.large,
                    expand: true,
                    onPressed: () {},
                  ),
                  CupertinoNativeButton(
                    title: "Small Capsule",
                    style: CupertinoNativeButtonStyle.tinted,
                    controlSize: CupertinoNativeControlSize.small,
                    onPressed: () {},
                  ),
                  CupertinoNativeButton(
                    title: "Mini",
                    style: CupertinoNativeButtonStyle.tinted,
                    controlSize: CupertinoNativeControlSize.mini,
                    onPressed: () {},
                  ),
                ],
              ),
              const Text(
                "Glass Circle Interface",
                style: TextStyle(backgroundColor: Colors.red),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: .start,
                children: [
                  CupertinoNativeButton(
                    title: "Rec",
                    systemImage: "mic.fill",
                    style: CupertinoNativeButtonStyle.glass,
                    borderShape: CupertinoNativeButtonBorderShape.circle,
                    labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                    controlSize: CupertinoNativeControlSize.large,
                    color: Colors.red,

                    onPressed: () =>
                        setState(() => _lastAction = "Circle Mic Record"),
                  ),
                  const SizedBox(width: 20),
                  CupertinoNativeButton(
                    title: "Call",
                    systemImage: "phone.fill",
                    style: CupertinoNativeButtonStyle.filled,
                    borderShape: CupertinoNativeButtonBorderShape.capsule,
                    controlSize: CupertinoNativeControlSize.large,
                    color: Colors.green,
                    width: 120,
                    height: 50,
                    onPressed: () =>
                        setState(() => _lastAction = "Call Capsule"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlert(BuildContext context) {
    CupertinoNativeAlert.show(
      title: "Mobile Data is Off",
      message: "Turn on mobile data or start using Wi-Fi to access data.",
      actions: [
        CupertinoNativeAlertAction(
          title: "Settings",
          onPressed: () {
            setState(() => _lastAction = "Alert: Settings");
          },
        ),
        CupertinoNativeAlertAction(
          title: "OK",
          isDestructive: true,

          onPressed: () {
            setState(() => _lastAction = "Alert: OK");
          },
        ),
      ],
    );
  }
}
