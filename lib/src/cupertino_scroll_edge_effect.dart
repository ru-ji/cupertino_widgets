import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart'
    show CupertinoColors, CupertinoDynamicColor;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'cupertino_native_tab_bar.dart' show CupertinoNativeScrollEdgeEffect;

/// Which screen edge a [CupertinoScrollEdgeEffect] hugs.
enum CupertinoScrollEdgeEffectEdge { top, bottom }

/// A Flutter recreation of iOS 26's **scroll edge effect** — the progressive
/// blur + adaptive tint that SwiftUI applies where content meets the screen
/// edge (under navigation bars, behind floating tab bars).
///
/// SwiftUI's effect is bound to native scroll views, so it can't be applied
/// to standalone bars hosted in Flutter; this widget reproduces it with a
/// true variable-radius Gaussian: a bundled fragment shader drives
/// [BackdropFilter] layers (two separable passes via [ui.ImageFilter.shader])
/// whose sigma falls off continuously from the screen edge — no visible
/// steps — and whose sampling is bounded to the effect's own rectangle, so
/// nothing outside the page (e.g. the black gap revealed during a back-swipe)
/// can smear in. The bounds are recomputed **at paint time**, so they track
/// the header collapsing under a scroll and the page sliding during route
/// transitions. A tint wash covering the full effect area — white in light
/// mode, near-black in dark mode — sits on top. When shader image filters
/// aren't supported (non-Impeller), stacked fixed-sigma backdrop blurs
/// approximate the falloff instead.
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
class CupertinoScrollEdgeEffect extends StatefulWidget {
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

  @override
  State<CupertinoScrollEdgeEffect> createState() =>
      _CupertinoScrollEdgeEffectState();
}

class _CupertinoScrollEdgeEffectState extends State<CupertinoScrollEdgeEffect> {
  static const String _shaderAsset =
      'packages/cupertino_widgets/shaders/cupertino_edge_blur.frag';

  /// Peak blur at the screen edge, logical px. The system effect is lighter
  /// than it looks — its reach comes from spanning a tall region, not from a
  /// heavy sigma (compare Music/Library on iOS 26).
  static const double _maxSigma = 3;

  /// Fallback-only: blur strength per horizontal slice, outermost first —
  /// the shader's cosine falloff sampled at each slice's center, scaled to
  /// [_maxSigma].
  static const _fallbackSigmas = [2.97, 2.82, 2.49, 2.04, 1.53, 0.96, 0.48, 0.09];

  static ui.FragmentProgram? _cachedProgram;
  static Future<ui.FragmentProgram?>? _programFuture;

  ui.FragmentShader? _horizontalPass;
  ui.FragmentShader? _verticalPass;
  ModalRoute<Object?>? _route;

  /// Reaches the blur render object so route transitions can repaint it (its
  /// sampling bounds are in screen coordinates and must track the sliding
  /// page — see [_onRouteTick]).
  final GlobalKey _blurKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final program = _cachedProgram;
    if (program != null) {
      _horizontalPass = program.fragmentShader();
      _verticalPass = program.fragmentShader();
    } else if (ui.ImageFilter.isShaderFilterSupported) {
      _loadProgram();
    }
  }

  void _loadProgram() {
    _programFuture ??= () async {
      try {
        return await ui.FragmentProgram.fromAsset(_shaderAsset);
      } catch (_) {
        try {
          // Running from within this package itself (tests).
          return await ui.FragmentProgram.fromAsset(
            'shaders/cupertino_edge_blur.frag',
          );
        } catch (_) {
          return null; // Fallback slices take over permanently.
        }
      }
    }();
    _programFuture!.then((program) {
      _cachedProgram = program;
      if (program == null || !mounted) return;
      setState(() {
        _horizontalPass = program.fragmentShader();
        _verticalPass = program.fragmentShader();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _detachRouteListeners();
      _route = route;
      route?.animation?.addListener(_onRouteTick);
      route?.secondaryAnimation?.addListener(_onRouteTick);
    }
  }

  void _detachRouteListeners() {
    _route?.animation?.removeListener(_onRouteTick);
    _route?.secondaryAnimation?.removeListener(_onRouteTick);
  }

  /// Whether the enclosing route is mid-push/pop/back-swipe.
  bool _transitioning = false;

  static bool _moving(Animation<double>? a) =>
      a != null && a.value > 0 && a.value < 1;

  /// The enclosing route is sliding (push/pop/back-swipe). The page's screen
  /// position changes without any layout, so the blur wouldn't repaint on its
  /// own — repaint it each transition tick to keep its bounds current.
  void _onRouteTick() {
    _blurKey.currentContext?.findRenderObject()?.markNeedsPaint();
    final transitioning =
        _moving(_route?.animation) || _moving(_route?.secondaryAnimation);
    if (transitioning != _transitioning && mounted) {
      setState(() => _transitioning = transitioning);
    }
  }

  @override
  void dispose() {
    _detachRouteListeners();
    _horizontalPass?.dispose();
    _verticalPass?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The tint deliberately matches the page background exactly (no
    // lightening/darkening tweak): the edge melts into the page in both
    // appearances, like the system effect. Pass [color] when the page sits
    // on something other than systemBackground (e.g. a grouped background)
    // so the wash harmonizes with it.
    final tint = CupertinoDynamicColor.resolve(
      widget.color ?? CupertinoColors.systemBackground,
      context,
    );
    final isTop = widget.edge == CupertinoScrollEdgeEffectEdge.top;
    final hard = widget.style == CupertinoNativeScrollEdgeEffect.hard;

    // Tint wash on the EXACT same falloff as the shader blur (same exponent,
    // same 3% dead zone) — same fade-out start, same effective height, so
    // the two layers read as one effect that dies together at the boundary.
    final peak = hard ? 0.6 : 0.45;
    const steps = 16;
    double alphaAt(double t) =>
        peak * math.pow(math.cos(t * math.pi / 2), 1.5).toDouble();
    // Same 3% dead zone as the shader: nothing is painted at the boundary.
    const fadeEnd = 0.97;
    final wash = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            for (var i = 0; i <= steps; i++)
              tint.withValues(alpha: alphaAt(i / steps)),
            tint.withValues(alpha: 0),
          ],
          stops: [for (var i = 0; i <= steps; i++) (i / steps) * fadeEnd, 1.0],
        ),
      ),
    );

    // While the route slides, the tint carries the effect alone. A backdrop
    // filter sampling a scene that is being transformed mid-flight picks up
    // the seam where the sliding page's own backdrop ends — a hard vertical
    // line across the bar. Nothing in the page is scrolled during a
    // transition, so the blur has nothing to earn there.
    // ponytail: blur suppressed for the transition's duration; if the
    // pop-in ever reads as abrupt, cross-fade it back in instead.
    if (_transitioning) {
      return IgnorePointer(child: ClipRect(child: wash));
    }

    final hPass = _horizontalPass;
    final vPass = _verticalPass;
    if (!ui.ImageFilter.isShaderFilterSupported ||
        hPass == null ||
        vPass == null) {
      return _slicesFallback(wash, isTop);
    }

    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ShaderEdgeBlur(
              key: _blurKey,
              horizontalPass: hPass,
              verticalPass: vPass,
              maxSigma: _maxSigma,
              topEdge: isTop,
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            ),
            wash,
          ],
        ),
      ),
    );
  }

  /// Pre-Impeller fallback: slices of increasing fixed backdrop blur toward
  /// the screen edge approximate the shader's continuous falloff.
  Widget _slicesFallback(Widget wash, bool isTop) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sliceHeight = constraints.maxHeight / _fallbackSigmas.length;
            return Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < _fallbackSigmas.length; i++)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: isTop ? i * sliceHeight : null,
                    bottom: isTop ? null : i * sliceHeight,
                    height: sliceHeight + 0.5,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: _fallbackSigmas[i],
                          sigmaY: _fallbackSigmas[i],
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                wash,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The two-pass shader blur as a render object: the shader's sampling bounds
/// (screen coordinates) are computed in [paint], so they are correct on every
/// painted frame — while the header collapses under a scroll, and while the
/// page slides during a route transition — instead of freezing at whatever
/// they were on the last rebuild.
class _ShaderEdgeBlur extends LeafRenderObjectWidget {
  const _ShaderEdgeBlur({
    super.key,
    required this.horizontalPass,
    required this.verticalPass,
    required this.maxSigma,
    required this.topEdge,
    required this.devicePixelRatio,
  });

  final ui.FragmentShader horizontalPass;
  final ui.FragmentShader verticalPass;
  final double maxSigma;
  final bool topEdge;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShaderEdgeBlur(
        horizontalPass: horizontalPass,
        verticalPass: verticalPass,
        maxSigma: maxSigma,
        topEdge: topEdge,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShaderEdgeBlur renderObject,
  ) {
    renderObject
      ..horizontalPass = horizontalPass
      ..verticalPass = verticalPass
      ..maxSigma = maxSigma
      ..topEdge = topEdge
      ..devicePixelRatio = devicePixelRatio;
  }
}

class _RenderShaderEdgeBlur extends RenderBox {
  _RenderShaderEdgeBlur({
    required ui.FragmentShader horizontalPass,
    required ui.FragmentShader verticalPass,
    required double maxSigma,
    required bool topEdge,
    required double devicePixelRatio,
  }) : _horizontalPass = horizontalPass,
       _verticalPass = verticalPass,
       _maxSigma = maxSigma,
       _topEdge = topEdge,
       _devicePixelRatio = devicePixelRatio;

  ui.FragmentShader _horizontalPass;
  set horizontalPass(ui.FragmentShader value) {
    if (identical(value, _horizontalPass)) return;
    _horizontalPass = value;
    markNeedsPaint();
  }

  ui.FragmentShader _verticalPass;
  set verticalPass(ui.FragmentShader value) {
    if (identical(value, _verticalPass)) return;
    _verticalPass = value;
    markNeedsPaint();
  }

  double _maxSigma;
  set maxSigma(double value) {
    if (value == _maxSigma) return;
    _maxSigma = value;
    markNeedsPaint();
  }

  bool _topEdge;
  set topEdge(bool value) {
    if (value == _topEdge) return;
    _topEdge = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  /// One retained layer per pass; the vertical pass samples the horizontal
  /// pass's output, composing a full 2D Gaussian. Held via [LayerHandle] —
  /// without one the framework disposes the layer whenever an ancestor drops
  /// its layer subtree (route transitions do), and the next paint would then
  /// write to a disposed layer.
  final LayerHandle<BackdropFilterLayer> _horizontalLayer =
      LayerHandle<BackdropFilterLayer>();
  final LayerHandle<BackdropFilterLayer> _verticalLayer =
      LayerHandle<BackdropFilterLayer>();

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    // Screen-space rect of the effect, current for THIS frame (includes any
    // in-flight route-transition transform).
    final bounds = localToGlobal(Offset.zero) & size;
    _configure(_horizontalPass, 1, 0, bounds);
    _configure(_verticalPass, 0, 1, bounds);

    final horizontalLayer = _horizontalLayer.layer ??= BackdropFilterLayer();
    horizontalLayer.filter = ui.ImageFilter.shader(_horizontalPass);
    context.pushLayer(horizontalLayer, _paintNothing, offset);

    final verticalLayer = _verticalLayer.layer ??= BackdropFilterLayer();
    verticalLayer.filter = ui.ImageFilter.shader(_verticalPass);
    context.pushLayer(verticalLayer, _paintNothing, offset);
  }

  static void _paintNothing(PaintingContext context, Offset offset) {}

  void _configure(
    ui.FragmentShader shader,
    double dirX,
    double dirY,
    Rect bounds,
  ) {
    final dpr = _devicePixelRatio;
    // Floats 0,1 (u_size) and sampler 0 (the backdrop) are engine-filled.
    shader
      ..setFloat(2, _maxSigma * dpr)
      ..setFloat(3, dirX)
      ..setFloat(4, dirY)
      ..setFloat(5, bounds.left * dpr)
      ..setFloat(6, bounds.top * dpr)
      ..setFloat(7, bounds.width * dpr)
      ..setFloat(8, bounds.height * dpr)
      ..setFloat(9, _topEdge ? 0.0 : 1.0);
  }

  @override
  void dispose() {
    _horizontalLayer.layer = null;
    _verticalLayer.layer = null;
    super.dispose();
  }
}
