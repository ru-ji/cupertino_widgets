import 'package:flutter/cupertino.dart'
    show CupertinoColors, NavigationBarBottomMode;
import 'package:flutter/widgets.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoSliverAppBar] — the Flutter-drawn iOS 26 navigation bar: pure
/// scroll-edge-effect background (no solid fill, no border), the blur-morph
/// title collapse, Liquid Glass leading/trailing buttons (trailing shares one
/// capsule like glassEffectUnion), and a search field that morphs to the top
/// as glass with a ✕ sliding in from the screen edge. Below iOS 26 the page
/// falls back to Flutter's CupertinoSliverNavigationBar automatically.
class AppBarDemoPage extends StatefulWidget {
  const AppBarDemoPage({super.key});

  @override
  State<AppBarDemoPage> createState() => _AppBarDemoPageState();
}

class _AppBarDemoPageState extends State<AppBarDemoPage> {
  static const _albums = [
    ('Country gold, summer soul', Color(0xFFF7B733), Color(0xFFFC4A1A)),
    ('Neon nights', Color(0xFF7F7FD5), Color(0xFF91EAE4)),
    ('Back porch country', Color(0xFF56AB2F), Color(0xFFA8E063)),
    ('Deep focus', Color(0xFF1A2980), Color(0xFF26D0CE)),
    ('Morning coffee', Color(0xFFBA5370), Color(0xFFF4E2D8)),
    ('Night runner', Color(0xFF41295A), Color(0xFF2F0743)),
    ('Rainy day jazz', Color(0xFF2C3E50), Color(0xFF4CA1AF)),
    ('Summer drive', Color(0xFFFF512F), Color(0xFFDD2476)),
  ];

  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.systemBackground.resolveFrom(context);

    final results = _albums
        .where((a) => a.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ColoredBox(
      color: background,
      child: DefaultTextStyle(
        style: rowTitleStyle(context),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverAppBar.search(
              largeTitle: 'Records',
              //subtitle: '${_albums.length} albums',
              centerTitle: true,
              // iOS 26 back button: a glass circle with just the chevron.
              leading: CupertinoAppBarAction.back(
                onPressed: () => Navigator.pop(context),
              ),
              // Photos-style: icon actions get their own glass circle,
              // label actions a capsule (separateTrailing: false unions
              // adjacent label actions into one capsule).
              trailing: [
                CupertinoAppBarAction(
                  icon: CupertinoNativeIcon.symbol(CupertinoSymbols.ellipsis),
                  onPressed: () {},
                ),
                CupertinoAppBarAction(label: 'Select', onPressed: () {}),
              ],
              separateTrailing: true,
              // The .search constructor builds the glass field itself (44pt
              // capsule, magnifier prefix, focus managed internally).
              // bottomMode.automatic collapses it with the scroll (before
              // the page moves); .always keeps it visible.
              searchPlaceholder: 'Search records',
              bottomMode: NavigationBarBottomMode.automatic,
              onSearchChanged: (q) => setState(() => _query = q),
              onSearchActiveChanged: (active) {
                setState(() {
                  _searching = active;
                  if (!active) _query = '';
                });
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
              // Cross-fade between browse and search content, timed with the
              // bar's 300ms search morph, instead of an instant swap.
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_searching),
                    // Stretch so children get the full width, exactly as the
                    // SliverList this replaced laid them out.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _searching
                        ? [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                _query.isEmpty ? 'SUGGESTED' : 'RESULTS',
                                style: footnoteStyle(context),
                              ),
                            ),
                            for (final (title, start, end) in results) ...[
                              _AlbumRow(title: title, start: start, end: end),
                            ],
                            if (results.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No results for "$_query"',
                                  style: footnoteStyle(context),
                                ),
                              ),
                          ]
                        : [
                            Text(
                              'Scroll — the large title blur-morphs into the '
                              'inline one over a pure scroll-edge effect. Tap '
                              'the search field to see the glass morph.',
                              style: footnoteStyle(context),
                            ),
                            const SizedBox(height: 16),
                            for (final (title, start, end) in _albums) ...[
                              _AlbumCard(title: title, start: start, end: end),
                              const SizedBox(height: 14),
                            ],
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(colors: [start, end]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: rowTitleStyle(context))),
          const DisclosureChevron(),
        ],
      ),
    );
  }
}
