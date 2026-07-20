<!-- ═══════════════════════════════════════════════════════════════════════
  HOW TO EDIT THIS README FOR PUB.DEV
  ───────────────────────────────────────────────────────────────────────
  📸 IMAGES — pub.dev only renders images with ABSOLUTE https URLs.
     1. Store your screenshots/GIFs in this repo under  doc/images/
        (e.g. doc/images/slider.png, doc/images/scaffold.gif).
     2. Reference them with the raw.githubusercontent.com URL pattern:
        https://raw.githubusercontent.com/<GITHUB_USER>/<REPO>/main/doc/images/slider.png
        Replace <GITHUB_USER>/<REPO> everywhere below once, after you push.
     3. Record demos at 2x device scale, crop to the phone frame, and keep
        GIFs under ~5 MB or pub.dev will feel sluggish.
     4. BONUS: add up to 10 entries to pubspec.yaml's `screenshots:` field —
        those appear in pub.dev's screenshot carousel:
          screenshots:
            - description: 'Native slider in a Settings-style page'
              path: doc/images/slider.png
  Every spot that needs an image below is marked with:  📸 IMAGE
═══════════════════════════════════════════════════════════════════════ -->

# cupertino_widgets

Real UIKit & SwiftUI views inside Flutter — not lookalikes. Native buttons,
toggles, sliders, menus, lists, sheets, tab bars, a full SwiftUI scaffold,
and the iOS 26 **Liquid Glass** material, all driven from Dart at 120 fps.

<!-- 📸 IMAGE: hero — a banner or 3-phone montage of the demo app.
<p align="center">
  <img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/hero.png" width="800" alt="cupertino_widgets demo" />
</p>
-->

## Why

Flutter's Cupertino widgets are pixel-perfect *drawings* of iOS controls.
This package embeds the *real* controls as platform views: system animations,
haptics, Liquid Glass materials, Dynamic Type and accessibility come for free
— while your app state stays in Dart with Flutter-style APIs
(`value` / `onChanged`, `const` constructors).

## Requirements

| | |
|---|---|
| iOS deployment target | 13.0+ (package links anywhere; views render on **iOS 15+**) |
| Liquid Glass features | iOS 26+ (`glass` button styles, `CupertinoNativeGlassContainer`, glass tab bar/toolbars) — older versions get graceful material fallbacks |
| Integration | Swift Package Manager (no CocoaPods needed) |

## Widgets

| Widget | Native counterpart |
|---|---|
| `CupertinoNativeButton` | SwiftUI `Button` (filled / tinted / plain / **glass** / **glassProminent**) |
| `CupertinoNativeToggle` | `UISwitch` |
| `CupertinoNativeSlider` | `UISlider` |
| `CupertinoNativeSegmentedControl` | `UISegmentedControl` |
| `CupertinoNativeMenu` | `UIMenu` (sections, submenus, toggles, destructive) |
| `CupertinoNativeTextField` | `UITextField` (autofill, QuickType) |
| `CupertinoNativeDatePicker` | compact `UIDatePicker` (popover calendar / time wheel) |
| `CupertinoNativeProgressIndicator` | `ProgressView` (linear / circular) |
| `CupertinoNativeAlert` | `UIAlertController` |
| `CupertinoNativeList` / `CupertinoNativeForm` | SwiftUI-style inset-grouped sections (26 pt corners on iOS 26) |
| `CupertinoNativeGlassContainer` | **Liquid Glass** `glassEffect` in a `GlassEffectContainer` |
| `CupertinoNativeTabBar` | `UITabBar` (Liquid Glass, split search tab, minimize-on-scroll) |
| `CupertinoNativeScaffold` | SwiftUI `NavigationStack` + `TabView` (collapsing large titles, native push/pop, `.searchable`) |
| `CupertinoNativeSheet` | `UISheetPresentationController` (detents, grabber, pinned native app bar) |

## Quick start

```yaml
dependencies:
  cupertino_widgets: ^0.0.1
```

```dart
import 'package:cupertino_widgets/cupertino_widgets.dart';

CupertinoNativeSlider(
  value: _volume,
  onChanged: (v) => setState(() => _volume = v),
)
```

<!-- 📸 IMAGE: slider — the Settings-style volume page from the example app.
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/slider.png" width="320" alt="Native slider" />
-->

### Buttons & icons (SF Symbols)

```dart
CupertinoNativeButton(
  title: 'Call',
  icon: CupertinoNativeIcon.symbol(CupertinoSymbols.phoneFill),
  style: CupertinoNativeButtonStyle.glassProminent, // Liquid Glass on iOS 26
  borderShape: CupertinoNativeButtonBorderShape.capsule,
  onPressed: () {},
)
```

Icons come from a typo-safe `CupertinoSymbols` enum, any raw SF Symbol name
via `CupertinoNativeIcon.named('...')`, or any Flutter `IconData` rendered
natively via `CupertinoNativeIcon.flutter(...)`.

<!-- 📸 IMAGE: buttons — the contact-card demo page (call/message/record row).
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/buttons.png" width="320" alt="Native buttons" />
-->

### Liquid Glass container (iOS 26)

```dart
CupertinoNativeGlassContainer(
  shape: CupertinoNativeGlassShape.capsule,
  variant: CupertinoGlassVariant.clear,  // .regular (default) or .clear
  interactive: true,               // system touch shimmer
  onPressed: () {},                // makes it a glass button
  icon: CupertinoNativeIcon.symbol(CupertinoSymbols.paintbrush),
  child: Text('Now Playing'),      // Flutter content on top of the glass
)
```

The glass is a real `glassEffect` refracting whatever Flutter renders behind
it. `CupertinoGlassVariant.clear` picks the more transparent clear glass for
media-rich backdrops. Check `CupertinoNativeGlassContainer.isSupported` to
branch on devices below iOS 26 (they render a material fallback).
`CupertinoNativeTextField(glassEffect: true)` takes the same variants via
`glassVariant`, plus `glassInteractive` to toggle its touch shimmer.

<!-- 📸 IMAGE (GIF recommended): glass — the Liquid Glass demo hero card over
     the colorful backdrop, finger pressing the shapes.
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/glass.gif" width="320" alt="Liquid Glass container" />
-->

### Native list & form

```dart
CupertinoNativeList(
  sections: [
    CupertinoNativeListSection(
      header: 'General',
      rows: [
        CupertinoNativeListRow(
          id: 'about',
          title: 'About',
          icon: CupertinoNativeIcon.symbol(CupertinoSymbols.infoCircleFill),
          showChevron: true,
        ),
      ],
    ),
  ],
  onRowTap: (id) => debugPrint(id),
)
```

Section corners automatically match the running iOS version (26 pt concentric
on iOS 26, 10 pt earlier). Toggle rows report through `onToggle`.

<!-- 📸 IMAGE: list — the Settings-clone List & Form demo page.
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/list.png" width="320" alt="Native list and form" />
-->

### Full native scaffold

Bodies are Flutter routes rendered inside a SwiftUI `NavigationStack` +
`TabView`: large titles collapse on native scroll, tabs minimize (iOS 26),
push/pop transitions and back-swipe are the system's.

```dart
// main.dart — bodies run in their own engines, resolved from a route table:
void main() {
  if (CupertinoNativeScaffold.maybeRun(scaffoldRoutes())) return;
  runApp(const MyApp());
  CupertinoNativeScaffold.prewarm(); // optional: pay engine cold-start now
}

CupertinoNativeScaffold(
  appBar: CupertinoNativeAppBar(title: 'Library'),
  tabBar: CupertinoNativeTabBar(tabs: [/* ... */]),
  // A native spinner shows while a body engine boots its first frame.
  // Pass false to show nothing (the page background) instead:
  showLoadingIndicator: false,
)
```

<!-- 📸 IMAGE (GIF recommended): scaffold — scroll collapsing the large title
     and minimizing the tab bar.
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/scaffold.gif" width="320" alt="Native scaffold" />
-->

### Native sheet

```dart
await CupertinoNativeSheet.show(
  route: 'newEvent',                       // same route table as the scaffold
  appBar: CupertinoNativeAppBar(
    title: 'New Event',
    leading: [
      CupertinoNativeBarItem(
        icon: CupertinoNativeIcon.symbol(CupertinoSymbols.xmark),
        actionId: 'close',
      ),
    ],
    trailing: [CupertinoNativeBarItem(title: 'Add', actionId: 'add')],
  ),
  bottom: CupertinoNativeSheetSegmentedControl(segments: ['Event', 'Reminder']),
  detents: [CupertinoNativeSheetDetent.medium, CupertinoNativeSheetDetent.large],
  showGrabber: true,
  onBarAction: (id) => CupertinoNativeSheet.dismiss(),
); // completes on dismissal
```

A real `UISheetPresentationController`: the presenting page recedes, content
scrolls natively under the pinned bar, and pull-down-at-top drags the sheet
between detents.

<!-- 📸 IMAGE (GIF recommended): sheet — presenting the New Event sheet,
     scrolling it, dragging between detents.
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/sheet.gif" width="320" alt="Native sheet" />
-->

## Performance

### How scaffold bodies live

Every `CupertinoNativeScaffold` (and native sheet) body is a Flutter page
running in its own lightweight engine, spawned from one shared
`FlutterEngineGroup` — engines share the GPU context and Dart snapshot, so
each one costs a few MB, not a whole app. Their lifecycle:

1. **Lazy** — a body boots the first time its page or tab is shown, never
   before.
2. **Kept across visits** — when you leave a scaffold, its root bodies are
   *parked*: detached from the screen, still running, rendering nothing.
   Re-opening the same route re-attaches the parked body instantly — no
   reload, no spinner, scroll position and state intact.
3. Pushed detail pages are per-instance and are discarded when popped.

### `prewarm()` — what it's for and how to use it

The one boot users can still feel is the **very first engine after app
launch**: the engine group pays its one-time cost (loading the Dart
snapshot, creating the isolate group) right when the user opens the first
native screen. `prewarm()` moves that cost to app startup instead, where
nobody notices it:

```dart
void main() {
  if (CupertinoNativeScaffold.maybeRun(routes)) return;
  runApp(const MyApp());
  CupertinoNativeScaffold.prewarm(); // after runApp — non-blocking
}
```

That plain call is all most apps need. Pass `routes:` only when a specific
page must show its Flutter content with **zero** delay on its very first
open — typically a scaffold visible immediately at launch:

```dart
CupertinoNativeScaffold.prewarm(routes: ['home']);
```

This fully boots and parks that body at startup. It's a trade-off: **each
listed route boots on the main thread in the first seconds of the app and
holds memory from then on**, so listing many routes slows startup — prewarm
only what the user sees first, and let everything else load lazily. (Debug
builds JIT-compile Dart on top of all this; judge real latency in
`--release`.)

## Example app

The [example](example/) is a full iOS-styled catalog — every widget in a
realistic Settings-style screen. Run it on an iOS 26 device to see the
Liquid Glass features.

<!-- 📸 IMAGE: catalog — the example app home list (light + dark side by side).
<img src="https://raw.githubusercontent.com/GITHUB_USER/REPO/main/doc/images/catalog.png" width="640" alt="Example catalog" />
-->

## Platform notes

- **iOS only.** On other platforms widgets render simple Flutter fallbacks so
  shared code still builds.
- **Standard Flutter effect widgets work on the native views.** `Transform`
  (translate / scale / rotate), clipping, `Offstage` and `Visibility` reach
  the underlying `UIView` through platform-view mutators, and `Opacity`
  fades them too — with one iOS caveat: Liquid Glass / material backgrounds
  (`UIVisualEffectView`) keep rendering their effect at full intensity under
  an inherited alpha, so to fully hide a glass surface use
  `Visibility`/`Offstage` (or the component's own parameters). The example's
  *Widget Effects* page exercises all of these on live native views.
- **Works from iOS 15 up.** iOS 26 is not required: on iOS 15–18 every
  component renders its classic pre-26 system style (e.g. material blur
  instead of Liquid Glass, Flutter's `CupertinoSliverNavigationBar` behind
  `CupertinoSliverAppBar`), and iOS 26-only properties (glass styles, corner
  concentricity, scroll edge effect tuning) are simply ignored. The native
  scaffold needs iOS 16+.
- Scaffold/sheet **bodies** run in embedded engines and must use drawn Flutter
  widgets (no platform views inside them) and self-size
  (`Column(mainAxisSize: MainAxisSize.min)`).
- The package integrates via **Swift Package Manager**; Flutter 3.24+ with
  SPM enabled.
