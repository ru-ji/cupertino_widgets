import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';
import 'package:haze/haze.dart';

import '../widgets/settings_ui.dart';

/// The scroll edge effect in its two hosting models, over identical content.
///
/// What to look for is the **tint**, not the blur. iOS derives a mix-in colour
/// from what passes under the bar, so the system's scrim recedes over a
/// bright, busy band and comes back over a flat one, while the blur holds.
/// [CupertinoScrollEdgeEffect] takes a fixed colour and cannot do that.
///
/// * **Native** runs in a [CupertinoNativeScaffold]: a real SwiftUI
///   `ScrollView` owns the content, so the system draws its own effect on it,
///   adaptation included.
/// * **Flutter page** has no scroll view for a native effect to attach to —
///   one hosted over it draws nothing at all — so the bar draws the
///   recreation.
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
              'a dark one. The native screen thins its tint over the bright '
              'band and keeps the blur; the Flutter one holds a single tint '
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
              title: 'Flutter page (Haze)',
              subtitle: 'The recreation, fixed tint',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _HazeProbe(),
                  title: 'Back',
                ),
              ),
            ),
            SettingsRow(
              title: 'Isolate the layers',
              subtitle: 'Blur alone, tint alone, and neither',
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _LayerIsolationProbe(),
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

/// The recreation, over the same bands: a Flutter scrollable with
/// [CupertinoScrollEdgeEffect] stacked over its top edge.
///
/// Its tint is fixed, and that is not a shortcut — it is the only thing
/// available. The system effect hosted over this same page draws nothing at
/// all: `UIScrollEdgeEffect` blurs the content of the scroll view it belongs
/// to, and a Flutter page has no scroll view for it to belong to. Tested, not
/// assumed.
class _HazeProbe extends StatelessWidget {
  const _HazeProbe();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const Positioned.fill(
            child: SingleChildScrollView(child: EdgeEffectProbeBody()),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Roughly what the native probe's effect spans: its region is the
            // bar's safe area (status bar + large title) and the fade runs
            // past it. A box only as tall as the inline bar squeezes the
            // whole profile — plateau and fade — into half the distance, and
            // no tuning can look right compressed.
            //
            // It is also the effect's cost: every pixel in here runs the
            // kernel twice. Doubling the height doubles the GPU work.
            height: top + 44 + 110,
            child: const CupertinoScrollEdgeEffect(),
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
                  'Haze',
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

/// Runs each layer of the effect on its own, so an artefact can be attributed
/// instead of guessed at. Tap the title to cycle.
///
/// * **Both** — the effect as shipped.
/// * **Blur only** — no tint. A line still there is the blur's, or the
///   filter's own boundary.
/// * **Tint only** — no blur, so no `BackdropFilter` is pushed at all. A line
///   still there cannot be a filter artefact; it is the gradient, or it is
///   not ours.
/// * **Neither** — nothing is drawn. A line still there is coming from the
///   page, not from the effect.
class _LayerIsolationProbe extends StatefulWidget {
  const _LayerIsolationProbe();

  @override
  State<_LayerIsolationProbe> createState() => _LayerIsolationProbeState();
}

class _LayerIsolationProbeState extends State<_LayerIsolationProbe> {
  static const _modes = ['Both', 'Blur only', 'Tint only', 'Neither'];
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final blur = _mode == 0 || _mode == 1;
    final tint = _mode == 0 || _mode == 2;
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const Positioned.fill(
            child: SingleChildScrollView(child: EdgeEffectProbeBody()),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 44 + 110,
            child: IgnorePointer(
              child: Haze(
                sigma: blur ? 12 : 0,
                falloff: 1,
                plateau: 0.3,
                tint: tint
                    ? CupertinoDynamicColor.resolve(
                        CupertinoColors.systemBackground,
                        context,
                      )
                    : null,
                tintOpacity: 0.55,
              ),
            ),
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      setState(() => _mode = (_mode + 1) % _modes.length),
                  child: Text(
                    _modes[_mode],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      color: CupertinoColors.white,
                    ),
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
