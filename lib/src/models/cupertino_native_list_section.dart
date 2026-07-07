import 'cupertino_native_list_row.dart';

/// A `Section` of a [CupertinoNativeList] or [CupertinoNativeForm], with an
/// optional header/footer and its rows — mirroring SwiftUI's
/// `Section(header:footer:) { ... }`.
class CupertinoNativeListSection {
  final String? header;
  final String? footer;
  final List<CupertinoNativeListRow> rows;

  const CupertinoNativeListSection({
    this.header,
    this.footer,
    this.rows = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'header': header,
      'footer': footer,
      'rows': rows.map((r) => r.toMap()).toList(),
    };
  }
}
