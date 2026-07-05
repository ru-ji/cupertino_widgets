import 'models/cupertino_native_bar_item.dart';

/// How a [CupertinoNativeAppBar] title is displayed, mapped to SwiftUI's
/// `.toolbarTitleDisplayMode(...)` (iOS 17+, with a sensible fallback to
/// `.navigationBarTitleDisplayMode` below that).
///
/// - [automatic]: inherit the surrounding context (large at a stack root,
///   inline once pushed).
/// - [inline]: always a small centered title.
/// - [inlineLarge]: an inline title rendered at the large title's size
///   (iOS 17+; falls back to [large]).
/// - [large]: the collapsible large title.
enum CupertinoNativeToolbarTitleDisplayMode { automatic, inline, inlineLarge, large }

/// Navigation-bar configuration for a [CupertinoNativeScaffold] page: the
/// title, how the title is displayed, and the leading/trailing bar items.
///
/// This is a plain immutable config object (not a widget). It is serialized and
/// handed to the native SwiftUI `NavigationStack`, which owns the actual bar —
/// there is no standalone `UINavigationBar` widget.
class CupertinoNativeAppBar {
  final String title;

  /// How the title is displayed. Defaults to
  /// [CupertinoNativeToolbarTitleDisplayMode.automatic].
  final CupertinoNativeToolbarTitleDisplayMode titleDisplayMode;

  /// Leading/trailing entries: [CupertinoNativeBarItem] renders its own glass
  /// capsule, [CupertinoNativeBarItemGroup] renders several buttons sharing
  /// one capsule.
  final List<CupertinoNativeBarEntry> leading;
  final List<CupertinoNativeBarEntry> trailing;

  const CupertinoNativeAppBar({
    required this.title,
    this.titleDisplayMode = CupertinoNativeToolbarTitleDisplayMode.automatic,
    this.leading = const [],
    this.trailing = const [],
  });

  /// Serialized form consumed by `CupertinoNativeScaffold` to configure each
  /// page's native navigation bar.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'displayMode': titleDisplayMode.name,
      'leading': leading.map((e) => e.toMap()).toList(),
      'trailing': trailing.map((e) => e.toMap()).toList(),
    };
  }
}
