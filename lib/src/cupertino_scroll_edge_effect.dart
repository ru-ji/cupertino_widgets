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
/// * **a plateau on the tint, a plain descent on the blur** — the wash is
///   held constant over the bar region and then released on a curve whose
///   start and end are both undetectable, while the blur descends across the
///   whole span. Sharing one profile between them was tried in both
///   directions and is worse each way: what makes an alpha fade invisible is
///   not what makes a radius ramp invisible. Compared against the real thing
///   side by side on the example's Scroll Edge Effect page.
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
    this.intensity = 1,
  }) : assert(intensity >= 0 && intensity <= 1);

  final CupertinoScrollEdgeEffectEdge edge;

  /// `soft` (blur-forward) or `hard` (denser scrim, the more defined
  /// boundary iOS uses for high-legibility areas). `automatic` is treated as
  /// `soft`, like the system default.
  final CupertinoScrollEdgeEffectStyle style;

  /// Tint override. Defaults to the resolved system background.
  final Color? color;

  /// Scales the whole effect, 0 (nothing) to 1 (full). Both the blur and the
  /// scrim ramp together — the system's effect is not always on, it comes up
  /// from zero as the header takes the content under it.
  final double intensity;

  /// Peak blur at the edge. Apple's bar materials use a 24pt radius, and a
  /// Gaussian takes sigma as radius/2.
  static const double _sigma = 5;

  /// Holds the TINT at full strength over the top third before it starts to
  /// fade. This is what the first recreation lacked: its wash began decaying
  /// at the very first pixel, so covering the bar area at all meant being
  /// heavy everywhere — the grey band. Held, then released, it can be lighter
  /// overall and still read stronger where it matters.
  ///
  /// The blur takes no plateau, and is otherwise untouched from Haze 0.1.1.
  /// Held at full radius it would have to shed all of it in what is left of
  /// the span, and the end of the heavy blur becomes an edge; its plain
  /// cosine descent measured better than every profile tried against it.
  static const double _plateau = 0.3;

  /// 1 = the bare smootherstep. Raising it tightens the decay toward the
  /// plateau; the system's fade is the long, patient version.
  static const double _falloff = 1.0;

  /// Peak opacity of the wash. `hard` is the denser, more opaque boundary
  /// iOS uses where legibility beats seamlessness.
  static const double _softTint = 0.55;
  static const double _hardTint = 0.85;

  @override
  Widget build(BuildContext context) {
    final hard = style == CupertinoScrollEdgeEffectStyle.hard;
    return IgnorePointer(
      child: Haze(
        edge: edge == CupertinoScrollEdgeEffectEdge.top
            ? HazeEdge.top
            : HazeEdge.bottom,
        sigma: _sigma * intensity,
        falloff: _falloff,
        plateau: _plateau,
        tint: CupertinoDynamicColor.resolve(
          color ?? CupertinoColors.systemBackground,
          context,
        ),
        tintOpacity: (hard ? _hardTint : _softTint) * intensity,
      ),
    );
  }
}
