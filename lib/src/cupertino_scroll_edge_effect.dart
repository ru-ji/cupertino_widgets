import 'package:flutter/cupertino.dart'
    show CupertinoColors, CupertinoDynamicColor;
import 'package:flutter/widgets.dart';
import 'package:haze/haze.dart';

import 'cupertino_native_tab_bar.dart' show CupertinoScrollEdgeEffectStyle;

/// Which screen edge a [CupertinoScrollEdgeEffect] hugs.
enum CupertinoScrollEdgeEffectEdge { top, bottom }

/// iOS 26's **scroll edge effect** — the progressive blur plus gradient scrim
/// that appears where content meets the screen edge — with the system's own
/// parameters filled in.
///
/// SwiftUI's effect is bound to native scroll views, so it can't be applied to
/// standalone bars hosted in Flutter. This is the [Haze] progressive blur
/// tuned to match it:
///
/// * **sigma 12** — Apple's bar materials use a 24pt blur radius (the values
///   in Apple's published iOS 18 Figma, transcribed by Haze-for-Compose's
///   `CupertinoMaterials`), and that blur takes sigma as `radius / 2`.
/// * **falloff 3** — puts the scrim at ~0.5 alpha over the bar's own centre
///   and the blur's reach a fade-extension past it, matching the widely used
///   recreation of the system effect (ProgressiveBlurHeader's defaults).
/// * **tint** — the page background, white in light mode and black in dark,
///   so the edge melts into the page. The system derives this colour from the
///   content beneath the scroll view; pass [color] when the page sits on
///   something other than `systemBackground` (e.g. a grouped background).
///
/// Place it in a `Stack` behind a bar, sized to the region that should melt
/// into the edge:
///
/// ```dart
/// Stack(children: [
///   Positioned(top: 0, left: 0, right: 0, height: 120,
///     child: CupertinoScrollEdgeEffect(edge: CupertinoScrollEdgeEffectEdge.top)),
///   ...bar content...
/// ])
/// ```
class CupertinoScrollEdgeEffect extends StatelessWidget {
  const CupertinoScrollEdgeEffect({
    super.key,
    this.edge = CupertinoScrollEdgeEffectEdge.top,
    this.style = CupertinoScrollEdgeEffectStyle.soft,
    this.color,
  });

  final CupertinoScrollEdgeEffectEdge edge;

  /// `soft` (blur-forward) or `hard` (denser scrim, the more defined
  /// boundary iOS uses for high-legibility areas). `automatic` is treated as
  /// `soft`, like the system default.
  final CupertinoScrollEdgeEffectStyle style;

  /// Tint override. Defaults to the resolved system background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hard = style == CupertinoScrollEdgeEffectStyle.hard;
    return IgnorePointer(
      child: Haze(
        edge: edge == CupertinoScrollEdgeEffectEdge.top
            ? HazeEdge.top
            : HazeEdge.bottom,
        sigma: 12,
        falloff: 3,
        tint: CupertinoDynamicColor.resolve(
          color ?? CupertinoColors.systemBackground,
          context,
        ),
        tintOpacity: hard ? 0.85 : 0.7,
      ),
    );
  }
}
