import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cupertino_native_tab_bar.dart' show CupertinoScrollEdgeEffectStyle;

/// **Probe.** iOS 26's own scroll edge effect, hosted as a native view over
/// Flutter content — as opposed to [CupertinoScrollEdgeEffect], which recreates
/// it with a progressive blur drawn by Flutter.
///
/// It exists to settle one question by looking at it: `UIScrollEdgeEffect`
/// belongs to a scroll view and blurs *that scroll view's* content, and a
/// Flutter page has no scroll view — so the prediction is that this paints
/// nothing at all. The reason it is worth testing anyway is that
/// `glassEffect`, under the same constraint, demonstrably refracts the Flutter
/// content behind our glass container: these effects may sample their backdrop
/// rather than their content, and if this one does, the system's adaptive tint
/// is available to Flutter pages after all.
///
/// Stack it over the top of a scrollable, sized to the region that should melt
/// into the edge. It never takes touches.
///
/// Keep or delete depending on what it shows.
class CupertinoSystemScrollEdgeEffect extends StatelessWidget {
  const CupertinoSystemScrollEdgeEffect({
    super.key,
    this.style = CupertinoScrollEdgeEffectStyle.soft,
    this.inset = 100,
  });

  /// `soft` (blurred boundary) or `hard` (nearly opaque). `automatic` is sent
  /// as `soft`, which is what the system picks for a scrolling page.
  final CupertinoScrollEdgeEffectStyle style;

  /// Height of the region the effect draws in — the safe area a bar would have
  /// inset on the hosted scroll view, since that is the area the effect is
  /// drawn against.
  final double inset;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: UiKitView(
        viewType:
            'com.example.cupertino_widgets/cupertino_native_scroll_edge_effect',
        layoutDirection: TextDirection.ltr,
        creationParams: {
          'style': style == CupertinoScrollEdgeEffectStyle.hard
              ? 'hard'
              : 'soft',
          'inset': inset,
        },
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
    );
  }
}
