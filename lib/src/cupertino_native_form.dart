import 'package:flutter/widgets.dart';

import 'internal/native_collection_view.dart';
import 'models/cupertino_native_list_section.dart';

/// A native SwiftUI `Form` with `Section`s — the grouped, settings-style
/// container used for forms on iOS. Same section/row model as
/// [CupertinoNativeList]; use [CupertinoNativeListRowType.toggle] rows for
/// native switches.
///
/// ```dart
/// CupertinoNativeForm(
///   sections: [
///     CupertinoNativeListSection(
///       header: 'Notifications',
///       rows: [
///         CupertinoNativeListRow(
///           id: 'push', title: 'Push', type: CupertinoNativeListRowType.toggle,
///           toggleValue: true,
///         ),
///       ],
///     ),
///   ],
///   onToggle: (id, value) => debugPrint('$id -> $value'),
/// )
/// ```
///
/// By default the form self-sizes to its content (iOS 16+). Pass a [height]
/// (optionally with [scrollable]) for a fixed, internally-scrolling region.
class CupertinoNativeForm extends StatelessWidget {
  final List<CupertinoNativeListSection> sections;
  final double? height;
  final bool scrollable;
  final Color? tint;

  /// Corner radius of the grouped section cards. Null matches the running iOS
  /// version's Settings app automatically (26 on iOS 26+, 10 on earlier
  /// releases); set a value to override.
  final double? cornerRadius;

  final void Function(String id)? onRowTap;
  final void Function(String id, bool value)? onToggle;

  const CupertinoNativeForm({
    super.key,
    required this.sections,
    this.height,
    this.scrollable = false,
    this.tint,
    this.cornerRadius,
    this.onRowTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return NativeCollectionView(
      variant: 'form',
      style: 'automatic',
      sections: sections,
      height: height,
      scrollable: scrollable,
      tint: tint,
      cornerRadius: cornerRadius,
      onRowTap: onRowTap,
      onToggle: onToggle,
    );
  }
}
