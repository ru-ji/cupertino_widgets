import 'package:flutter/cupertino.dart';

/// Content hosted INSIDE a [CupertinoNativeGlassContainer]'s glass, via its
/// `route`. The container spawns an engine on this route and applies
/// `glassEffect` to the hosted view, so this text is real glass content —
/// drawn above the material and never lensed at the edges, even with the
/// clear variant.
///
/// It runs in its own isolate, like a scaffold body: no access to the page's
/// state, so it is written self-contained.
class GlassNowPlayingBody extends StatelessWidget {
  const GlassNowPlayingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Now Playing — Deep Focus',
          style: TextStyle(
            fontSize: 17,
            decoration: TextDecoration.none,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
