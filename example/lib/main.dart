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
  final String _tabSelection = 'home';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Native CupertinoNative Menu')),

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
                        _isMapEnabled =
                            !v; // just flipping the same state for demo
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
                    style: CupertinoNativeButtonStyle
                        .glassProminent, // Added style
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TabViewExamplePage(),
                        ),
                      );
                    },
                    child: const Text('TabView Widget'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FullscreenTabViewPage(),
                        ),
                      );
                    },
                    child: const Text('Fullscreen TabView'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
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

// -- Home -------------------------------------------------------------------
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10000,
      width: MediaQuery.sizeOf(context).width,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 48),
            Icon(Icons.home, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Home',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            Text(
              'This content is rendered by Flutter inside a screen '
              'controlled by a native SwiftUI TabView.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'The native ScrollView wraps this Flutter view, so '
              'scrolling is handled by SwiftUI \u2014 not Flutter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.search, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Search',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Profile ----------------------------------------------------------------
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48),
          CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text('John Doe', textAlign: TextAlign.center),
          Text('john.doe@example.com', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// -- Settings ---------------------------------------------------------------
class SettingsTabPage extends StatelessWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48),
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text('Notifications', style: TextStyle(fontSize: 18)),
          Divider(),
          Text('Privacy', style: TextStyle(fontSize: 18)),
          Divider(),
          Text('About', style: TextStyle(fontSize: 18)),
          Divider(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TabView Example Page — uses the native tab bar + Flutter body pages
// ---------------------------------------------------------------------------
class TabViewExamplePage extends StatefulWidget {
  const TabViewExamplePage({super.key});

  @override
  State<TabViewExamplePage> createState() => _TabViewExamplePageState();
}

class _TabViewExamplePageState extends State<TabViewExamplePage> {
  String _selectedTab = 'home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native TabView Demo')),
      body: _buildBody(),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: CupertinoNativeTabView(
          accentColor: Colors.blue,
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
              title: 'Profile',
              systemImage: 'person.fill',
              id: 'profile',
            ),
            CupertinoNativeTab(
              title: 'Settings',
              systemImage: 'gear',
              id: 'settings',
            ),
          ],
          initialSelection: _selectedTab,
          onSelectionChanged: (id) {
            setState(() => _selectedTab = id);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 'home':
        return const HomeTabPage();
      case 'search':
        return const SearchTabPage();
      case 'profile':
        return const ProfileTabPage();
      case 'settings':
        return const SettingsTabPage();
      default:
        return const HomeTabPage();
    }
  }
}

// ---------------------------------------------------------------------------
// Entry point for FullscreenTabView — single function for all tabs
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void tabEntry() {
  CupertinoNativeFullscreenTabView.run({
    'home': () => const HomeTabPage(),
    'search': () => const SearchTabPage(),
    'profile': () => const ProfileTabPage(),
    'settings': () => const SettingsTabPage(),
  });
}

// ---------------------------------------------------------------------------
// Fullscreen TabView Page — native SwiftUI TabView with Flutter entry points
// ---------------------------------------------------------------------------
class FullscreenTabViewPage extends StatelessWidget {
  const FullscreenTabViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoNativeFullscreenTabView(
        entryPoint: 'tabEntry',
        accentColor: Colors.blue,
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
            role: CupertinoNativeTabRole.search,
          ),
          CupertinoNativeTab(
            title: 'Profile',
            systemImage: 'person.fill',
            id: 'profile',
          ),
          CupertinoNativeTab(
            title: 'Settings',
            systemImage: 'gear',
            id: 'settings',
          ),
        ],
        initialSelection: 'home',
        onSelectionChanged: (id) {
          debugPrint('Fullscreen tab changed: $id');
        },
      ),
    );
  }
}
