import 'package:flutter/cupertino.dart';

import '../widgets/settings_ui.dart';

/// Search tab body. Under the native scaffold this sits below a real
/// search-role tab (the system search field); here it lists trending queries.
/// Drawn Flutter widgets only — it is also used as a scaffold body.
class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  static const _trending = [
    ('Liquid Glass', 'Design'),
    ('SwiftUI interop', 'Development'),
    ('SF Symbols 7', 'Design'),
    ('Platform views', 'Flutter'),
    ('NavigationStack', 'Development'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
          child: Text('TRENDING', style: footnoteStyle(context)),
        ),
        SettingsSection(
          cardColor: CupertinoColors.systemGrey6,
          children: [
            for (final (query, category) in _trending)
              SettingsRow(
                title: query,
                subtitle: category,
                showChevron: true,
                onTap: () {},
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
