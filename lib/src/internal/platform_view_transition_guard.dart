import 'package:flutter/widgets.dart';

/// Hides its [child] while the enclosing route is animating in or out.
///
/// Every `CupertinoNative*` widget hosts a real `UIView`. The compositor
/// positions those on the platform thread, a step behind the Flutter layer
/// they belong to — at rest that is invisible, but during a route transition
/// the Flutter content slides and the native view does not follow in step. It
/// hangs at the wrong offset for the length of the animation: a native field
/// stranded beside its own label, a glass bar button from the outgoing page
/// left sitting over the incoming one as a bare rounded square.
///
/// Not paintable around: the offset comes from the embedder, so no Dart-side
/// transform fixes it. Dropping the native view for the duration of the
/// transition is the standard trade — the layout is kept (nothing reflows) and
/// the view comes back the frame the route settles.
///
/// A no-op outside a route (`ModalRoute.of` is null), so platform views hosted
/// in a native scaffold body are untouched.
class PlatformViewTransitionGuard extends StatefulWidget {
  const PlatformViewTransitionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<PlatformViewTransitionGuard> createState() =>
      _PlatformViewTransitionGuardState();
}

class _PlatformViewTransitionGuardState
    extends State<PlatformViewTransitionGuard> {
  /// This route's own push/pop progress.
  Animation<double>? _animation;

  /// This route's progress under a route pushed on top of it — the case that
  /// strands an outgoing page's native views over the incoming page.
  Animation<double>? _secondaryAnimation;

  bool _settled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route?.animation == _animation &&
        route?.secondaryAnimation == _secondaryAnimation) {
      return;
    }
    _detach();
    _animation = route?.animation;
    _secondaryAnimation = route?.secondaryAnimation;
    _animation?.addListener(_onTick);
    _secondaryAnimation?.addListener(_onTick);
    _settled = _isSettled;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    _animation?.removeListener(_onTick);
    _secondaryAnimation?.removeListener(_onTick);
  }

  /// Fully on screen, with nothing sliding over it.
  bool get _isSettled =>
      (_animation?.isCompleted ?? true) &&
      (_secondaryAnimation?.isDismissed ?? true);

  // Per animation tick, but only rebuilds on the two frames the state flips.
  void _onTick() {
    final settled = _isSettled;
    if (settled != _settled) setState(() => _settled = settled);
  }

  @override
  Widget build(BuildContext context) {
    // `.maintain` keeps size, state and animations — the platform view is
    // never torn down and rebuilt, only dropped from the frame, so there is no
    // native re-creation cost and no flash of an empty control on arrival.
    return Visibility.maintain(visible: _settled, child: widget.child);
  }
}
