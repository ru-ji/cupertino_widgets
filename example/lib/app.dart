import 'package:flutter/material.dart';

import 'pages/home_page.dart';

/// Root app. This stays a [MaterialApp] on purpose: the plugin's platform
/// views read `Theme.of(context)` to sync light/dark with the native side,
/// and Material's iOS defaults give Cupertino page transitions. Every visible
/// screen, however, is built from Cupertino + native widgets.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// App-wide theme mode — toggled by the home app bar's brightness action.
  /// Starts on the device setting.
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => ClipRRect(
        // EXPERIMENT — delete this ClipRRect (and _UnderlayMarker below)
        // to go back to stock behaviour. It clips nothing: it sits one
        // point outside the screen. It is a flag to the iOS embedder.
        //
        // The embedder composites a native view by cutting the region
        // where the Flutter content above it will land OUT of the root
        // surface, and drawing that content into a separate overlay view
        // on top of the native one:
        //
        //     background_canvas->ClipRect(full_joined_rect, kDifference);
        //     // engine/src/flutter/flow/view_slicer.cc
        //
        // Invisible while the overlay paints the same pixels back, which
        // holds for opaque content and fails for anything that samples
        // what is behind it: the overlay is cleared to transparent before
        // the content renders into it, so a BackdropFilter up there
        // filters nothing and paints nothing. What is left is the hole.
        //
        // The embedder skips the cut for native views carrying a
        // non-rectangular clip (HasNonRectClipForUnderlayCutout, added
        // for flutter#150660 so a rounded native view's corners still
        // show what is behind them). One clip at the root reaches every
        // native view in the app through its mutators stack.
        //
        // Why at the ROOT and not around each view: a clip layer also
        // pushes itself onto every native view PREROLLED BEFORE IT
        // (pushClipRRectToVisitedPlatformViews). Per-view clips therefore
        // clip their predecessors to their own tiny box and erase them —
        // an app bar vanishes the moment a switch below it scrolls in. At
        // the root nothing has been visited yet, so there is nobody to
        // poison.
        clipper: const _UnderlayMarker(),
        clipBehavior: Clip.hardEdge,
        child: MaterialApp(
          title: 'Cupertino Widgets',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF007AFF),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF007AFF),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: mode,
          home: const HomePage(),
        ),
      ),
    );
  }
}

/// The shape of that marker clip.
///
/// Two properties are load-bearing, and both are why this is a clipper rather
/// than a `borderRadius`:
///
///  * **A non-zero radius.** `ClipRRectLayer::ApplyClip` sends a zero-radius
///    RRect down the plain-rect path (`clip_shape().IsRect()`), so the native
///    view's mutators stack ends up with `kClipRect` — which the embedder does
///    not count as a non-rectangular clip. Nothing changes. A radius of one
///    point is enough to take the other branch.
///  * **Larger than what it wraps.** With a radius, a clip that ends exactly
///    on the bounds no longer covers the corners, and the embedder answers
///    that by building a mask view per native view per frame — and rounding
///    off their corners. Inflated by one point, `TransformedRRectCoversBounds`
///    is satisfied and no mask is ever built.
class _UnderlayMarker extends CustomClipper<RRect> {
  const _UnderlayMarker();

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(
    Rect.fromLTWH(-1, -1, size.width + 2, size.height + 2),
    const Radius.circular(1),
  );

  @override
  bool shouldReclip(covariant CustomClipper<RRect> oldClipper) => false;
}
