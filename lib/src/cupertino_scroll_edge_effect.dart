import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart'
    show CupertinoColors, CupertinoDynamicColor;
import 'package:flutter/widgets.dart';

import 'cupertino_native_tab_bar.dart' show CupertinoNativeScrollEdgeEffect;

/// Which screen edge a [CupertinoScrollEdgeEffect] hugs.
enum CupertinoScrollEdgeEffectEdge { top, bottom }

/// A Flutter recreation of iOS 26's **scroll edge effect** — the progressive
/// blur + adaptive tint that SwiftUI applies where content meets the screen
/// edge (under navigation bars, behind floating tab bars).
///
/// SwiftUI's effect is bound to native scroll views, so it can't be applied
/// to standalone bars hosted in Flutter; this widget reproduces it with
/// stacked backdrop blurs (strongest at the edge, fading inward) and a tint
/// wash that resolves white in light mode and black in dark mode.
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
    this.style = CupertinoNativeScrollEdgeEffect.soft,
    this.color,
  });

  final CupertinoScrollEdgeEffectEdge edge;

  /// `soft` (blur-forward) or `hard` (stronger tint wash). `automatic` is
  /// treated as `soft`.
  final CupertinoNativeScrollEdgeEffect style;

  /// Tint override. Defaults to the resolved system background — white in
  /// light mode, black in dark mode, like the system effect.
  final Color? color;

  /// Blur strength per horizontal slice, outermost (screen edge) first. A
  /// quadratic falloff ending near zero so the innermost slice is
  /// imperceptible — no visible line where the blur stops.
  static const _sigmas = [10.0, 7.5, 5.4, 3.7, 2.3, 1.3, 0.6, 0.15];

  @override
  Widget build(BuildContext context) {
    final tint = CupertinoDynamicColor.resolve(
        color ?? CupertinoColors.systemBackground, context);
    final isTop = edge == CupertinoScrollEdgeEffectEdge.top;
    final hard = style == CupertinoNativeScrollEdgeEffect.hard;

    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sliceHeight = constraints.maxHeight / _sigmas.length;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Progressive blur: slices of increasing backdrop blur toward
                // the screen edge approximate SwiftUI's variable blur.
                for (var i = 0; i < _sigmas.length; i++)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: isTop ? i * sliceHeight : null,
                    bottom: isTop ? null : i * sliceHeight,
                    height: sliceHeight + 0.5,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                            sigmaX: _sigmas[i], sigmaY: _sigmas[i]),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                // Tint wash fading from the edge into the content.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          isTop ? Alignment.topCenter : Alignment.bottomCenter,
                      end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
                      colors: [
                        tint.withValues(alpha: hard ? 0.92 : 0.72),
                        tint.withValues(alpha: hard ? 0.62 : 0.42),
                        tint.withValues(alpha: hard ? 0.28 : 0.16),
                        tint.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.35, 0.68, 1],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
