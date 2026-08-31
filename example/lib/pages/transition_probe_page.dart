import 'package:cupertino_widgets/cupertino_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

import '../widgets/settings_ui.dart';

/// Two experiments, both about the same question: when does Flutter content
/// fail to cover a platform view?
///
/// **Overlap** is the one to read first, and it needs no navigation. A green
/// box painted after a native glass field covers it — that much is already
/// known to work. The second stack is identical but for a
/// [CupertinoScrollEdgeEffect] painted between the two. That effect is a
/// `BackdropFilter`, and it is what sits under the title inside the app bar's
/// header. If the green box stops covering the field once the filter is in
/// between, the filter is what breaks the overlay, and the collapsed title is
/// the same failure one layer up.
///
/// **Push** answers the other half: whether every native view on an outgoing
/// page strands over the incoming one, or only some. Same page twice, once
/// with a trailing bar action and once without.
class TransitionProbePage extends StatelessWidget {
  const TransitionProbePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Transition Probe',
      children: [
        SettingsSection(
          header: 'Overlap — control',
          footer:
              'A green box painted after the native field. It should cover '
              'it, and it does: an overlay is created for Flutter content '
              'painted above a platform view.',
          children: const [_OverlapStack(withFilter: false)],
        ),
        SettingsSection(
          header: 'Overlap — with a BackdropFilter between',
          footer:
              'The same stack, with a scroll edge effect painted between '
              'the field and the green box. If the green box no longer covers '
              'the field, the BackdropFilter is what stops the overlay from '
              'being created — which is exactly the app bar\'s situation.',
          children: const [_OverlapStack(withFilter: true)],
        ),
        SettingsSection(
          header: 'Overlap — a second platform view above',
          footer:
              'Field, then the green box, then a second native view on '
              'top. This is the app bar\'s exact shape: the list\'s field, '
              'then the title, then the bar\'s glass buttons. If the green box '
              'stops covering the field here, content sandwiched between two '
              'platform views is losing its overlay — and that is why the '
              'collapsed title goes under.',
          children: const [
            _OverlapStack(withFilter: false, secondNative: true),
          ],
        ),
        SettingsSection(
          header: 'Overlap — across repaint boundaries',
          footer:
              'Field and green box in separate sibling RepaintBoundaries, '
              'which is exactly how the Navigator holds two routes '
              '(routes.dart wraps every page in one). If the green box stops '
              'covering here, a retained layer boundary is what keeps the '
              'incoming page from covering the outgoing page\'s native views.',
          children: const [_OverlapStack(withFilter: false, isolated: true)],
        ),
        SettingsSection(
          header: 'Overlap — while moving',
          footer:
              'The control stack, slid back and forth continuously. A page '
              'transition is exactly this: the same content under an animating '
              'transform. If the green box only fails to cover while it moves, '
              'the platform view\'s position is being applied a frame behind '
              'the Flutter content, and no route is involved at all.',
          children: const [_MovingOverlap()],
        ),
        SettingsSection(
          header: 'Overlap — isolated and moving',
          footer:
              'Both at once: sibling repaint boundaries, under an '
              'animating transform. This is what a route transition actually '
              'is. If the field leaks far more here than under movement '
              'alone, the two compound — and that is the 44pt square, rather '
              'than the few pixels a frame of lag accounts for.',
          children: const [_MovingOverlap(isolated: true)],
        ),
        SettingsSection(
          header: 'Push',
          footer:
              'Each opens a page with the bar described, which then pushes '
              'a blank white page. Watch the top of the white page as it '
              'slides in: any shape there belongs to the page you left.',
          children: [
            SettingsRow(
              title: 'Bar: back button only',
              subtitle: 'One glass circle',
              showChevron: true,
              onTap: () => _push(context, withTrailing: false),
            ),
            SettingsRow(
              title: 'Bar: back button + trailing action',
              subtitle: 'Two glass circles, like the home bar',
              showChevron: true,
              onTap: () => _push(context, withTrailing: true),
            ),
          ],
        ),
      ],
    );
  }

  static void _push(BuildContext context, {required bool withTrailing}) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        title: 'Back',
        builder: (_) => _ProbeSource(withTrailing: withTrailing),
      ),
    );
  }
}

class _OverlapStack extends StatelessWidget {
  const _OverlapStack({
    required this.withFilter,
    this.secondNative = false,
    this.isolated = false,
  });

  final bool withFilter;

  /// Paints another platform view above the green box, reproducing the app
  /// bar's sandwich: platform view, Flutter content, platform view.
  final bool secondNative;

  /// Puts the field and the green box in sibling [RepaintBoundary]s, the way
  /// the Navigator holds two routes.
  final bool isolated;

  Widget _maybeIsolate({required Widget child}) =>
      isolated ? RepaintBoundary(child: child) : child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            Positioned.fill(
              child: _maybeIsolate(
                child: CupertinoNativeTextField(
                  placeholder: 'Native glass field',
                  glass: const CupertinoGlass(cornerRadius: 16),
                  height: 48,
                  prefixIcon: CupertinoNativeIcon.symbol(
                    CupertinoSymbols.magnifyingglass,
                  ),
                ),
              ),
            ),
            // The only difference between the two probes.
            if (withFilter)
              const Positioned.fill(child: CupertinoScrollEdgeEffect()),
            Positioned(
              left: 0,
              top: 0,
              width: 160,
              height: 48,
              child: _maybeIsolate(
                child: ColoredBox(
                  color: CupertinoColors.activeGreen.resolveFrom(context),
                ),
              ),
            ),
            if (secondNative)
              const Positioned(
                right: 0,
                top: 2,
                width: 44,
                height: 44,
                child: CupertinoNativeGlassContainer(
                  shape: CupertinoGlassShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The control stack under a continuously animating transform — a page
/// transition without the page.
class _MovingOverlap extends StatefulWidget {
  const _MovingOverlap({this.isolated = false});

  final bool isolated;

  @override
  State<_MovingOverlap> createState() => _MovingOverlapState();
}

class _MovingOverlapState extends State<_MovingOverlap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(60 * (_controller.value - 0.5), 0),
        child: child,
      ),
      child: _OverlapStack(withFilter: false, isolated: widget.isolated),
    );
  }
}

/// The page under test: its own bar, so the trailing action can be varied.
class _ProbeSource extends StatelessWidget {
  const _ProbeSource({required this.withTrailing});

  final bool withTrailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      body: DefaultTextStyle(
        style: rowTitleStyle(context),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverAppBar(
              largeTitle: withTrailing ? 'Back + trailing' : 'Back only',
              leading: CupertinoNativeButton(
                icon: CupertinoNativeIcon.symbol(
                  CupertinoSymbols.chevronBackward,
                ),
                style: CupertinoNativeButtonStyle.glass,
                borderShape: CupertinoNativeButtonBorderShape.circle,
                labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                onPressed: () => Navigator.pop(context),
              ),
              trailing: [
                if (withTrailing)
                  CupertinoNativeButton(
                    icon: CupertinoNativeIcon.named('moon'),
                    style: CupertinoNativeButtonStyle.glass,
                    borderShape: CupertinoNativeButtonBorderShape.circle,
                    labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                    onPressed: () {},
                  ),
              ],
              tintColor: CupertinoColors.systemGroupedBackground,
            ),
            SliverList.list(
              children: [
                SettingsSection(
                  header: 'Push',
                  footer: 'The next page is blank on purpose.',
                  children: [
                    SettingsRow(
                      title: 'Push the blank page',
                      titleColor: CupertinoColors.activeBlue.resolveFrom(
                        context,
                      ),
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          title: 'Back',
                          builder: (_) => const _ProbeTarget(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Tall enough to scroll the title into its collapsed state,
                // which is when the bar overlaps page content.
                const SizedBox(height: 900),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Deliberately empty and white: any shape appearing here during the push
/// belongs to the page being left.
class _ProbeTarget extends StatelessWidget {
  const _ProbeTarget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      body: DefaultTextStyle(
        style: rowTitleStyle(context),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverAppBar(
              largeTitle: 'Blank',
              leading: CupertinoNativeButton(
                icon: CupertinoNativeIcon.symbol(
                  CupertinoSymbols.chevronBackward,
                ),
                style: CupertinoNativeButtonStyle.glass,
                borderShape: CupertinoNativeButtonBorderShape.circle,
                labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                onPressed: () => Navigator.pop(context),
              ),
              tintColor: CupertinoColors.systemBackground,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Nothing is drawn on this page. Watch its top edge while it '
                  'slides in.',
                  style: footnoteStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
