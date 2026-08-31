import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// Side-by-side probe for the scroll edge effect: the system's own, and our
/// Haze recreation, over identical content.
///
/// What to look for is the **tint**, not the blur. iOS derives a mix-in colour
/// from whatever the scroll view is showing under the bar, so the scrim
/// recedes over a bright, busy band and comes back over a flat one — the blur
/// stays put throughout. [CupertinoScrollEdgeEffect] takes a fixed colour, so
/// its scrim holds the same weight over every band.
///
/// The two screens are not two settings of one thing; they are two hosting
/// models, which is the whole point:
///
/// * **Native** runs in a [CupertinoNativeScaffold] — a real SwiftUI
///   `ScrollView`, so `.scrollEdgeEffectStyle` has a scroll view to attach to
///   and the system draws the effect itself.
/// * **Flutter** runs in a [CupertinoSliverAppBar] over a `CustomScrollView`.
///   There is no `UIScrollView` anywhere in that page, so no native effect can
///   apply to it and the bar draws its own.
class EdgeEffectProbePage extends StatelessWidget {
  const EdgeEffectProbePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      largeTitle: false,
      title: 'Scroll Edge Effect',
      children: [
        SettingsSection(
          header: 'Compare',
          footer:
              'Scroll each one slowly with a bright band under the bar, then '
              'a dark one. The system effect thins its tint over bright, busy '
              'content and keeps the blur; the Haze version holds one tint '
              'throughout. Same content in both.',
          children: [
            SettingsRow(
              title: 'Native (SwiftUI ScrollView)',
              subtitle: 'The system effect, adaptive',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _NativeProbe(),
                  title: 'Back',
                ),
              ),
            ),
            SettingsRow(
              title: 'Flutter (Haze recreation)',
              subtitle: 'Fixed tint, progressive blur',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _HazeProbe(),
                  title: 'Back',
                ),
              ),
            ),
            SettingsRow(
              title: 'Flutter + native effect',
              subtitle: 'The system effect imported over Flutter content',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _NativeOverFlutterProbe(),
                  title: 'Back',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The system effect: a native scaffold, so the body really is inside a
/// SwiftUI `ScrollView` and `.scrollEdgeEffectStyle(.soft)` applies to it.
class _NativeProbe extends StatelessWidget {
  const _NativeProbe();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CupertinoNativeScaffold(
        scrollEdgeEffect: CupertinoScrollEdgeEffectStyle.soft,
        appBar: const CupertinoNativeAppBar(
          title: 'Native',
          titleDisplayMode: CupertinoNativeToolbarTitleDisplayMode.large,
        ),
        body: 'edgeEffectProbe',
      ),
    );
  }
}

/// The Haze recreation, over the same bands.
class _HazeProbe extends StatelessWidget {
  const _HazeProbe();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverAppBar(
            largeTitle: 'Haze',
            leading: CupertinoNativeButton(
              icon: CupertinoNativeIcon.symbol(
                CupertinoSymbols.chevronBackward,
                size: 20,
              ),
              style: CupertinoNativeButtonStyle.glass,
              borderShape: CupertinoNativeButtonBorderShape.circle,
              labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SliverToBoxAdapter(child: EdgeEffectProbeBody()),
        ],
      ),
    );
  }
}

/// The one that answers the question: a plain Flutter scrollable with the
/// SYSTEM effect hosted over its top edge, no native scroll view anywhere in
/// the page.
///
/// Three things to look for, in order:
///
/// 1. Does anything appear at all? If the strip stays perfectly clear as the
///    bands pass under it, the effect only ever sees the (empty) content of
///    the scroll view it belongs to, and a Flutter page can never have more
///    than a recreation.
/// 2. If something appears — is the blur sampling the bands behind it, or is
///    it a static wash?
/// 3. If it blurs — does the tint thin out over the bright bands and come back
///    over the flat ones? That is the adaptation, and the only reason to
///    consider replacing Haze.
class _NativeOverFlutterProbe extends StatelessWidget {
  const _NativeOverFlutterProbe();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const Positioned.fill(
            child: SingleChildScrollView(child: EdgeEffectProbeBody()),
          ),
          // The system effect, over Flutter pixels. Sized to the region a bar
          // would occupy, so it has somewhere to melt into.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 44,
            child: const CupertinoSystemScrollEdgeEffect(),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 16),
                CupertinoNativeButton(
                  icon: CupertinoNativeIcon.symbol(
                    CupertinoSymbols.chevronBackward,
                    size: 20,
                  ),
                  style: CupertinoNativeButtonStyle.glass,
                  borderShape: CupertinoNativeButtonBorderShape.circle,
                  labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Native effect',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The content every probe scrolls: alternating bands chosen for what they do
/// to a tint — saturated gradients, flat white, flat black, and a high-noise
/// band that stands in for a photograph.
class EdgeEffectProbeBody extends StatelessWidget {
  const EdgeEffectProbeBody({super.key});

  static const _bands = <(String, List<Color>)>[
    ('Flat white', [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
    ('Warm gradient', [Color(0xFFFF6B9D), Color(0xFFFFC371)]),
    ('Flat black', [Color(0xFF000000), Color(0xFF000000)]),
    ('Cool gradient', [Color(0xFF1A2980), Color(0xFF26D0CE)]),
    ('Busy — photo-like', [Color(0xFF7F7FD5), Color(0xFF86A8E7)]),
    ('Flat mid grey', [Color(0xFF808080), Color(0xFF808080)]),
    ('Vivid', [Color(0xFFFF0080), Color(0xFFFFD200)]),
    ('Flat white', [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
    ('Deep', [Color(0xFF0F2027), Color(0xFF2C5364)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, colors) in _bands)
          _Band(label: label, colors: colors),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 80),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.label, required this.colors});

  final String label;
  final List<Color> colors;

  /// Readable on either end of the palette, so the label never becomes the
  /// thing you are judging.
  Color get _ink {
    final c = colors.first;
    final luminance = (c.r * 0.299 + c.g * 0.587 + c.b * 0.114);
    return luminance > 0.6 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          color: _ink,
        ),
      ),
    );
  }
}
