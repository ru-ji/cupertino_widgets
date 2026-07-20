import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import 'cupertino_native_glass_container.dart';
import 'cupertino_native_tab_bar.dart' show CupertinoNativeScrollEdgeEffect;
import 'cupertino_native_text_field.dart';
import 'cupertino_scroll_edge_effect.dart';
import 'internal/ios_version.dart';
import 'models/cupertino_native_icon.dart';
import 'models/cupertino_symbols.dart';
import 'search_row_visibility.dart';

export 'search_row_visibility.dart' show CupertinoSearchRowVisibility;

/// A bar button of [CupertinoSliverAppBar]/[CupertinoAppBar], rendered as a
/// Liquid Glass control on iOS 26 — an **icon** becomes a 44pt glass circle
/// (like the iOS 26 back button / Photos "…"), a **label** becomes a glass
/// capsule (like Photos "Select"), and [child] embeds any drawn widget in a
/// capsule.
class CupertinoAppBarAction {
  const CupertinoAppBarAction({
    this.icon,
    this.label,
    this.child,
    required this.onPressed,
  }) : assert(
         icon != null || label != null || child != null,
         'Provide an icon, a label, or a child',
       );

  /// The iOS 26 back button: a glass circle with just the back chevron.
  factory CupertinoAppBarAction.back({required VoidCallback onPressed}) =>
      CupertinoAppBarAction(
        icon: CupertinoNativeIcon.symbol(CupertinoSymbols.chevronBackward),
        onPressed: onPressed,
      );

  /// SF Symbol — rendered natively, centered in a glass circle.
  final CupertinoNativeIcon? icon;

  /// Text — rendered in a glass capsule.
  final String? label;

  /// Arbitrary drawn content — rendered in a glass capsule.
  final Widget? child;

  final VoidCallback onPressed;

  bool get _isIconOnly => icon != null && label == null && child == null;
}

/// An iOS 26-style navigation bar drawn in Flutter.
///
/// SwiftUI's navigation title can't be hosted standalone in Flutter, so these
/// widgets recreate the iOS 26 look: no solid background or hairline — the
/// bar floats on a [CupertinoScrollEdgeEffect]; the large title collapses
/// with the system blur-morph; [leading]/[trailing] are Liquid Glass buttons
/// ([CupertinoAppBarAction]); the title sits centered ([centerTitle], the
/// default) or right after [leading], with an optional [subtitle].
///
/// The default constructor takes an optional [bottom] widget under the large
/// title that stays visible when scrolling. [CupertinoSliverAppBar.search]
/// builds the search bar itself (a glass `CupertinoNativeTextField`
/// configured with [searchPlaceholder]/[searchStyle]/[searchPrefixIcon]/
/// [searchSuffixIcon]): tapping it morphs the field to the top with a glass
/// ✕, and [bottomMode] — only available there — decides whether the row
/// collapses with the scroll ([NavigationBarBottomMode.automatic], the
/// default: consumed *before* the page starts scrolling, shrinking while its
/// content fades) or stays visible ([NavigationBarBottomMode.always]).
///
/// Below iOS 26 it falls back to Flutter's [CupertinoSliverNavigationBar]
/// (its `.search` variant with a [CupertinoSearchTextField] for the search
/// constructor), ignoring the iOS 26-only styling.
class CupertinoSliverAppBar extends StatefulWidget {
  const CupertinoSliverAppBar({
    super.key,
    required this.largeTitle,
    this.subtitle,
    this.centerTitle = true,
    this.expandedTitle = true,
    this.leading,
    this.trailing = const [],
    this.separateTrailing = false,
    this.bottom,
    this.bottomHeight = 44,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.soft,
    this.tintColor,
  }) : searchPlaceholder = null,
       searchStyle = null,
       searchPrefixIcon = null,
       searchSuffixIcon = null,
       bottomMode = NavigationBarBottomMode.always,
       onSearchChanged = null,
       onSearchActiveChanged = null,
       _searchable = false;

  /// A bar whose bottom row is a built-in search bar — the iOS 26 glass
  /// capsule, backed by a native `UITextField`. Focus, the top-dock morph and
  /// the glass ✕ are managed internally; listen to [onSearchChanged] for the
  /// query and [onSearchActiveChanged] to swap the page content.
  const CupertinoSliverAppBar.search({
    super.key,
    required this.largeTitle,
    this.subtitle,
    this.centerTitle = true,
    this.expandedTitle = true,
    this.leading,
    this.trailing = const [],
    this.separateTrailing = false,
    this.searchPlaceholder,
    this.searchStyle,
    this.searchPrefixIcon,
    this.searchSuffixIcon,
    double searchFieldHeight = 44,
    this.bottomMode = NavigationBarBottomMode.automatic,
    this.onSearchChanged,
    this.onSearchActiveChanged,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.soft,
    this.tintColor,
  }) : bottom = null,
       bottomHeight = searchFieldHeight,
       _searchable = true;

  final String largeTitle;

  /// Whether the expanded (large) title row exists. When false the bar is
  /// inline-only: the title is always in the bar and nothing collapses.
  final bool expandedTitle;

  /// Secondary line — under the large title (like Photos' "3,356 Items") and
  /// under the inline title when collapsed.
  final String? subtitle;

  /// Whether the inline title (and subtitle) sits centered in the bar
  /// (true, the default) or right after [leading].
  final bool centerTitle;

  final CupertinoAppBarAction? leading;

  /// Trailing actions. Icon-only actions always get their own glass circle;
  /// label/child actions share one capsule (the `glassEffectUnion` look)
  /// unless [separateTrailing] is true.
  final List<CupertinoAppBarAction> trailing;

  final bool separateTrailing;

  /// Widget under the large title (default constructor only). Unlike the
  /// search row, it is **always visible** — when scrolling, the large title
  /// collapses but the bottom stays pinned, like
  /// [NavigationBarBottomMode.always].
  final Widget? bottom;

  /// Height of the [bottom] slot — or of the built-in search field for
  /// [CupertinoSliverAppBar.search] (where it's named `searchFieldHeight`).
  /// Defaults to 44 — the iOS 26 glass capsule (same height as the system
  /// bar buttons).
  final double bottomHeight;

  /// Placeholder ("hint") text of the built-in search field.
  final String? searchPlaceholder;

  /// Text style of the built-in search field (`fontSize`, `fontWeight` and
  /// `color` are forwarded natively).
  final TextStyle? searchStyle;

  /// Leading SF Symbol inside the built-in search field. Defaults to the
  /// system magnifying glass.
  final CupertinoNativeIcon? searchPrefixIcon;

  /// Trailing SF Symbol inside the built-in search field.
  final CupertinoNativeIcon? searchSuffixIcon;

  /// Whether the search row collapses with the scroll (`automatic`) or stays
  /// visible (`always`). Only settable on [CupertinoSliverAppBar.search]; the
  /// default constructor's [bottom] always behaves as `always`.
  final NavigationBarBottomMode bottomMode;

  /// Fires on every keystroke in the built-in search field.
  final ValueChanged<String>? onSearchChanged;

  /// Fires when the search activates/deactivates, so the page can swap its
  /// content for a search view. Focus is managed internally.
  final ValueChanged<bool>? onSearchActiveChanged;

  /// True for [CupertinoSliverAppBar.search].
  final bool _searchable;

  final CupertinoNativeScrollEdgeEffect scrollEdgeEffect;

  /// Tint of the edge effect. Defaults to the system background.
  final Color? tintColor;

  @override
  State<CupertinoSliverAppBar> createState() => _CupertinoSliverAppBarState();
}

class _CupertinoSliverAppBarState extends State<CupertinoSliverAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _searchT = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  ScrollableState? _scrollableState;

  /// Search-row visibility (1 → 0 as the scroll consumes it), published to
  /// the hosted field via [CupertinoSearchRowVisibility] so native fields can
  /// fade their content natively. Updated from the delegate's build.
  final ValueNotifier<double> _searchRowVisibility = ValueNotifier<double>(1);

  /// Focus of the built-in search field — driven by the morph (focused on
  /// open, unfocused on close).
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'CupertinoSliverAppBar.search',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollableState?.position.isScrollingNotifier.removeListener(
      _handleScrollChange,
    );
    _scrollableState = Scrollable.maybeOf(context);
    _scrollableState?.position.isScrollingNotifier.addListener(
      _handleScrollChange,
    );
  }

  @override
  void dispose() {
    _scrollableState?.position.isScrollingNotifier.removeListener(
      _handleScrollChange,
    );
    _searchRowVisibility.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// iOS snap, mirroring CupertinoSliverNavigationBar's _handleScrollChange:
  /// when the scroll settles inside the search-row region (bottomMode
  /// .automatic) or the large-title region, animate the scroll position to
  /// the nearest edge so the bar never rests half-collapsed.
  void _handleScrollChange() {
    // Below iOS 26 the fallback CupertinoSliverNavigationBar snaps itself.
    if (!isIOS26OrLater) return;
    final ScrollPosition? position = _scrollableState?.position;
    if (position == null || !position.hasPixels || position.pixels <= 0.0) {
      return;
    }
    // During the search morph the header extents are driven by _controller,
    // and the active search view should scroll freely.
    if (_controller.value > 0.0) return;

    final bool collapsibleSearch =
        widget._searchable &&
        widget.bottomMode == NavigationBarBottomMode.automatic;
    final double bottomScrollOffset = collapsibleSearch
        ? _IOS26SliverAppBarDelegate._searchRowHeight(widget.bottomHeight)
        : 0.0;
    final double largeTitleHeight = _IOS26SliverAppBarDelegate._largeTitleH(
      expandedTitle: widget.expandedTitle,
      hasSubtitle: widget.subtitle != null,
    );

    double? target;
    if (bottomScrollOffset > 0.0 && position.pixels < bottomScrollOffset) {
      // Shifted by the dead zone: collapsing fully requires that much more
      // travel, so a light scroll settles back to the expanded state.
      target =
          position.pixels >
              bottomScrollOffset / 2 +
                  _IOS26SliverAppBarDelegate._collapseDeadZone
          ? bottomScrollOffset
          : 0.0;
    } else if (position.pixels > bottomScrollOffset &&
        position.pixels < bottomScrollOffset + largeTitleHeight) {
      target = position.pixels > bottomScrollOffset + largeTitleHeight / 2
          ? bottomScrollOffset + largeTitleHeight
          : bottomScrollOffset;
    }

    if (target != null && target <= position.maxScrollExtent) {
      position.animateTo(
        target,
        // Same timing as Flutter's nav bar, eyeballed on an iOS simulator.
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    }
  }

  void _setSearchActive(bool active) {
    if (active) {
      _controller.forward();
      _searchFocusNode.requestFocus();
    } else {
      _controller.reverse();
      _searchFocusNode.unfocus();
    }
    widget.onSearchActiveChanged?.call(active);
  }

  @override
  Widget build(BuildContext context) {
    if (!isIOS26OrLater) {
      final trailingRow = widget.trailing.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in widget.trailing)
                  _fallbackAction(context, action)!,
              ],
            );
      if (widget._searchable) {
        // Pre-iOS 26 look: Flutter's own search bar; the iOS 26-only glass
        // icon properties don't apply here and are ignored.
        return CupertinoSliverNavigationBar.search(
          searchField: CupertinoSearchTextField(
            placeholder: widget.searchPlaceholder,
            style: widget.searchStyle,
            onChanged: widget.onSearchChanged,
          ),
          bottomMode: widget.bottomMode,
          largeTitle: Text(widget.largeTitle),
          leading: _fallbackAction(context, widget.leading),
          trailing: trailingRow,
        );
      }
      return CupertinoSliverNavigationBar(
        largeTitle: Text(widget.largeTitle),
        leading: _fallbackAction(context, widget.leading),
        trailing: trailingRow,
        bottom: widget.bottom == null
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(widget.bottomHeight),
                child: widget.bottom!,
              ),
        bottomMode: widget.bottom == null
            ? null
            : NavigationBarBottomMode.always,
      );
    }
    final theme = CupertinoTheme.of(context);
    // Built once per build (not per animation tick): identical child
    // instances let elements/render objects be reused across ticks.
    final edgeEffect = RepaintBoundary(
      child: CupertinoScrollEdgeEffect(
        edge: CupertinoScrollEdgeEffectEdge.top,
        style: widget.scrollEdgeEffect,
        color: widget.tintColor,
      ),
    );
    final actionStyle = theme.textTheme.textStyle.copyWith(
      decoration: TextDecoration.none,
    );
    final leading = widget.leading == null
        ? null
        : _GlassActionButton(action: widget.leading!, labelStyle: actionStyle);
    final trailing = _buildTrailing(actionStyle);
    final closeButton = !widget._searchable
        ? null
        : CupertinoNativeGlassContainer(
            shape: CupertinoNativeGlassShape.circle,
            interactive: true,
            width: 44,
            height: 44,
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.xmark, size: 20),
            onPressed: () => _setSearchActive(false),
          );
    // The bottom slot: the built-in glass search field (.search) or the
    // user's always-visible bottom widget.
    final Widget? bottomSlot = widget._searchable
        ? CupertinoNativeTextField(
            placeholder: widget.searchPlaceholder,
            style: widget.searchStyle,
            glassEffect: true,
            glassCornerRadius: widget.bottomHeight / 2,
            height: widget.bottomHeight,
            // The capsule adopts the slot's height, so it physically
            // squeezes with the collapse instead of being clipped.
            fillHeight: true,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            prefixIcon:
                widget.searchPrefixIcon ??
                CupertinoNativeIcon.symbol(CupertinoSymbols.magnifyingglass),
            suffixIcon: widget.searchSuffixIcon,
            clearButtonMode: CupertinoNativeClearButtonMode.whileEditing,
            onChanged: widget.onSearchChanged,
          )
        : widget.bottom;

    return AnimatedBuilder(
      animation: _searchT,
      builder: (context, _) => SliverPersistentHeader(
        pinned: true,
        delegate: _IOS26SliverAppBarDelegate(
          largeTitle: widget.largeTitle,
          subtitle: widget.subtitle,
          centerTitle: widget.centerTitle,
          expandedTitle: widget.expandedTitle,
          leading: leading,
          trailing: trailing,
          searchField: bottomSlot,
          searchable: widget._searchable,
          fieldHeight: widget.bottomHeight,
          bottomMode: widget.bottomMode,
          closeButton: closeButton,
          edgeEffect: edgeEffect,
          searchRowVisibility: _searchRowVisibility,
          searchT: _searchT.value,
          onSearchOpen: () => _setSearchActive(true),
          topPadding: MediaQuery.paddingOf(context).top,
          // Native Flutter Cupertino nav bar text styles.
          inlineTitleStyle: theme.textTheme.navTitleTextStyle.copyWith(
            decoration: TextDecoration.none,
          ),
          largeTitleStyle: theme.textTheme.navLargeTitleTextStyle.copyWith(
            decoration: TextDecoration.none,
          ),
          subtitleStyle: theme.textTheme.tabLabelTextStyle.copyWith(
            fontSize: 13,
            decoration: TextDecoration.none,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  /// Trailing row: icon-only actions get their own circle; label/child
  /// actions share one capsule unless separated.
  Widget? _buildTrailing(TextStyle labelStyle) {
    if (widget.trailing.isEmpty) return null;
    final children = <Widget>[];
    final grouped = <CupertinoAppBarAction>[];

    void flushGroup() {
      if (grouped.isEmpty) return;
      if (grouped.length == 1 || widget.separateTrailing) {
        for (final action in grouped) {
          children.add(
            _GlassActionButton(action: action, labelStyle: labelStyle),
          );
        }
      } else {
        children.add(
          _GlassActionUnion(actions: List.of(grouped), labelStyle: labelStyle),
        );
      }
      grouped.clear();
    }

    for (final action in widget.trailing) {
      if (action._isIconOnly || widget.separateTrailing) {
        flushGroup();
        children.add(
          _GlassActionButton(action: action, labelStyle: labelStyle),
        );
      } else {
        grouped.add(action);
      }
    }
    flushGroup();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          children[i],
        ],
      ],
    );
  }

  Widget? _fallbackAction(BuildContext context, CupertinoAppBarAction? action) {
    if (action == null) return null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: action.onPressed,
      child:
          action.child ??
          Text(
            action.label ?? 'Back',
            style: CupertinoTheme.of(context).textTheme.navActionTextStyle,
          ),
    );
  }
}

class _IOS26SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  const _IOS26SliverAppBarDelegate({
    required this.largeTitle,
    required this.subtitle,
    required this.centerTitle,
    required this.expandedTitle,
    required this.leading,
    required this.trailing,
    required this.searchField,
    required this.searchable,
    required this.fieldHeight,
    required this.bottomMode,
    required this.closeButton,
    required this.edgeEffect,
    required this.searchRowVisibility,
    required this.searchT,
    required this.onSearchOpen,
    required this.topPadding,
    required this.inlineTitleStyle,
    required this.largeTitleStyle,
    required this.subtitleStyle,
  });

  // Geometry mirrors Flutter's CupertinoSliverNavigationBar
  // (_kNavBarLargeTitleHeightExtension = 52, _kNavBarBottomPadding = 8),
  // except the search field height, which is configurable and defaults to the
  // iOS 26 44pt capsule instead of Flutter's 36.
  static const double _barH = 44;
  static const double _largeExtension = 52;
  static const double _bottomPadding = 8;

  // The native search bar's fade window, in points of *height reduction*:
  // the hint text and prefix/suffix icons stay fully opaque for the first
  // 5pt of squeeze, then fade to nothing by 13pt — while the capsule itself
  // keeps shrinking, tracking the scroll (and the snap) proportionally.
  static const double _fadeStartShrink = 5;
  static const double _fadeEndShrink = 13;

  // Scroll dead zone before the capsule starts squeezing: the first points
  // of a scroll are absorbed by the row's padding, so a light scroll doesn't
  // instantly deform the search bar.
  static const double _collapseDeadZone = 10;

  /// How far the scroll-edge effect reaches BELOW the header. The system
  /// effect fades out past the bar; ending it at the header's own edge is
  /// what reads as an abrupt stop.
  static const double _effectOverhang = 24;

  static double _searchRowHeight(double fieldHeight) =>
      fieldHeight + _bottomPadding + 6;

  final String largeTitle;
  final String? subtitle;
  final bool centerTitle;
  final bool expandedTitle;
  final Widget? leading;
  final Widget? trailing;

  /// The bottom-slot widget: the built-in search field (permanently mounted —
  /// platform views must never be created mid-animation) or the user's
  /// always-visible `bottom`.
  final Widget? searchField;

  /// Whether [searchField] is the built-in search bar (tap-to-morph, glass ✕)
  /// rather than a plain always-visible bottom widget.
  final bool searchable;

  /// Height of the bottom slot (see [CupertinoSliverAppBar.bottomHeight]).
  final double fieldHeight;
  final NavigationBarBottomMode bottomMode;
  final Widget? closeButton;
  final Widget edgeEffect;

  /// Published search-row visibility, driven from [build] as the scroll
  /// consumes the row — native fields fade their content from it.
  final ValueNotifier<double> searchRowVisibility;

  /// 0 = resting, 1 = search active (field docked at the top).
  final double searchT;
  final VoidCallback onSearchOpen;

  final double topPadding;
  final TextStyle inlineTitleStyle;
  final TextStyle largeTitleStyle;
  final TextStyle subtitleStyle;

  bool get _hasSearch => searchField != null;
  bool get _collapsibleSearch =>
      _hasSearch && bottomMode == NavigationBarBottomMode.automatic;
  double get _searchRowH => _searchRowHeight(fieldHeight);
  double get _largeH =>
      _largeTitleH(expandedTitle: expandedTitle, hasSubtitle: subtitle != null);

  static double _largeTitleH({
    required bool expandedTitle,
    required bool hasSubtitle,
  }) => !expandedTitle
      ? 0
      : (hasSubtitle ? _largeExtension + 20 : _largeExtension);

  double get _restingMax =>
      topPadding + _barH + _largeH + (_hasSearch ? _searchRowH : 0);
  double get _restingMin =>
      topPadding +
      _barH +
      (_hasSearch && bottomMode == NavigationBarBottomMode.always
          ? _searchRowH
          : 0);
  double get _activeExtent => topPadding + fieldHeight + 12;

  @override
  double get minExtent => ui.lerpDouble(_restingMin, _activeExtent, searchT)!;

  @override
  double get maxExtent {
    final value = ui.lerpDouble(_restingMax, _activeExtent, searchT)!;
    return value < minExtent ? minExtent : value;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final height = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    // Sequenced collapse, like Flutter's bottomMode.automatic: the scroll
    // consumes the search row FIRST (it shrinks and fades to nothing before
    // the page moves), then the large title collapses.
    final consumedBySearch = _collapsibleSearch
        ? shrinkOffset.clamp(0.0, _searchRowH)
        : 0.0;
    final searchCollapseT = _collapsibleSearch
        ? consumedBySearch / _searchRowH
        : 0.0;
    final titleShrink = shrinkOffset - consumedBySearch;
    final tTitle = _largeH <= 0 ? 1.0 : (titleShrink / _largeH).clamp(0.0, 1.0);

    // All morph animations share the controller's curve and duration, but
    // the chrome (inline bar, glass buttons, titles) exits FAST: fully gone
    // by ~half of the search animation, like the system bar.
    final chrome = (1 - searchT * 2).clamp(0.0, 1.0);
    // The subtitle trails the title slightly through the collapse morph: its
    // progress runs off a lagged copy of the title's.
    final tTitleSub = (tTitle - 0.12).clamp(0.0, 1.0);
    final largeOpacity = !expandedTitle
        ? 0.0
        : (1 - tTitle / 0.75).clamp(0.0, 1.0) * chrome;
    final largeSubOpacity = !expandedTitle
        ? 0.0
        : (1 - tTitleSub / 0.75).clamp(0.0, 1.0) * chrome;
    // The collapsed (inline) title appears only as the large title collapses
    // on scroll — or permanently when the expanded title is disabled.
    final inlineT = !expandedTitle
        ? 1.0
        : ((tTitle - 0.55) / 0.45).clamp(0.0, 1.0);
    final inlineSubT = !expandedTitle
        ? 1.0
        : ((tTitleSub - 0.55) / 0.45).clamp(0.0, 1.0);
    final inlineSigma = (1 - inlineT) * 8;

    // Search slot geometry: shrinks with the collapse, travels on activation.
    // The capsule itself starts squeezing only past the dead zone — the
    // row's padding absorbs the first few points of scroll.
    final fieldConsumed = (consumedBySearch - _collapseDeadZone).clamp(
      0.0,
      fieldHeight,
    );
    final restFieldH = fieldHeight - fieldConsumed;
    final fieldH = ui
        .lerpDouble(restFieldH, fieldHeight, searchT)!
        .clamp(0.1, fieldHeight);
    final restTop =
        height - restFieldH - _bottomPadding * (1 - searchCollapseT);
    final fieldTop = ui.lerpDouble(restTop, topPadding + 4, searchT)!;
    // The field narrows as it rises, making room for the ✕.
    final fieldRight = ui.lerpDouble(16, 16 + 44 + 12, searchT)!;
    // Content fade driven by how many points of height the capsule has lost
    // (see _fadeStartShrink/_fadeEndShrink), not by the row fraction — the
    // native look: brief full-opacity squeeze, quick fade, bare capsule
    // continues shrinking to nothing.
    final fieldShrink = fieldHeight - restFieldH;
    final contentFade = searchT > 0
        ? 1.0
        : 1 -
              ((fieldShrink - _fadeStartShrink) /
                      (_fadeEndShrink - _fadeStartShrink))
                  .clamp(0.0, 1.0);
    // Let the hosted field react natively (Opacity can't fade platform-view
    // pixels). Listeners only push over a channel — no setState — so writing
    // during this build is safe.
    searchRowVisibility.value = contentFade;

    // Blur-morph + translate-from-below, like the system collapse. Title and
    // subtitle fade/travel on their own (lagged) progress so the subtitle
    // arrives just after the title.
    Widget inlineFade(Widget child, double t) => Opacity(
      opacity: t * chrome,
      child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
    );
    // With a subtitle the system inline bar drops the title to 15pt (and the
    // subtitle to 12pt) so both lines read as one compact block.
    Widget inlineTitleBlock = subtitle == null
        ? inlineFade(Text(largeTitle, style: inlineTitleStyle), inlineT)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centerTitle
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              inlineFade(
                Text(
                  largeTitle,
                  style: inlineTitleStyle.copyWith(fontSize: 15),
                ),
                inlineT,
              ),
              inlineFade(
                Text(subtitle!, style: subtitleStyle.copyWith(fontSize: 12)),
                inlineSubT,
              ),
            ],
          );
    if (inlineSigma > 0.1) {
      inlineTitleBlock = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: inlineSigma,
          sigmaY: inlineSigma,
        ),
        child: inlineTitleBlock,
      );
    }

    // The effect covers the bar + large-title region only — NOT the resting
    // search row. A search bar's taller header would otherwise stretch the
    // blur falloff and tint wash ~a row further down the content than a bar
    // without one (the HomePage look). As the row collapses — or the search
    // morph docks the field at the top — the effect grows back to full.
    final restEffectH = !_hasSearch
        ? height
        : (height -
                  _searchRowH *
                      (bottomMode == NavigationBarBottomMode.always
                          ? 1.0
                          : (1 - searchCollapseT)))
              .clamp(topPadding + _barH, height);
    // The system effect keeps thinning well past the bar's own bounds, so the
    // effect deliberately overflows the header (unclipped) — that trailing
    // reach is what makes it read as fading out instead of stopping.
    final effectH =
        ui.lerpDouble(restEffectH, height, searchT)! + _effectOverhang;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: effectH,
          child: edgeEffect,
        ),
        ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Inline bar row. Slides up out of view during the search morph
              // (platform views can't be opacity-faded).
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: _barH,
                child: Transform.translate(
                  offset: Offset(0, -(1 - chrome) * (topPadding + _barH)),
                  child: !centerTitle
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              if (leading != null) ...[
                                leading!,
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: inlineTitleBlock,
                                ),
                              ),
                              ?trailing,
                            ],
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            inlineTitleBlock,
                            if (leading != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: leading!,
                                ),
                              ),
                            if (trailing != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: trailing!,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              // Large title (+ subtitle), anchored above the search row. It sits
              // still while the search row collapses beneath it, then collapses
              // itself (sequenced like the system bar).
              Positioned(
                left: 16,
                right: 16,
                // Anchored 8pt above the search FIELD's top edge (not the search
                // row's slot, whose extra spacing floated the title 6pt too high
                // vs the system layout).
                bottom:
                    (_hasSearch
                        ? restFieldH + _bottomPadding * (1 - searchCollapseT)
                        : 0) +
                    _bottomPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: largeOpacity,
                      child: Text(
                        largeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: largeTitleStyle,
                      ),
                    ),
                    if (subtitle != null)
                      Opacity(
                        opacity: largeSubOpacity,
                        child: Text(subtitle!, style: subtitleStyle),
                      ),
                  ],
                ),
              ),
              if (_hasSearch) ...[
                // The user's search field, permanently mounted in a slot that
                // shrinks/fades with the collapse and travels to the top when
                // activated. (Opacity fades drawn fields; embedded platform-view
                // pixels are clipped by the shrinking slot instead.)
                Positioned(
                  left: 16,
                  right: fieldRight,
                  top: fieldTop,
                  height: fieldH,
                  child: _SearchSlot(
                    // A plain bottom widget receives its touches directly; the
                    // search field only becomes interactive once docked.
                    interactive: !searchable || searchT > 0.05,
                    onTap: onSearchOpen,
                    child: CupertinoSearchRowVisibility(
                      listenable: searchRowVisibility,
                      child: searchField!,
                    ),
                  ),
                ),
                // Glass ✕ — permanently mounted; rides in from beyond the right
                // screen edge, scaling up as it materializes next to the field.
                if (closeButton != null)
                  Positioned(
                    top: topPadding + 4,
                    right: 16,
                    width: 44,
                    height: 44,
                    child: Transform.translate(
                      offset: Offset((1 - searchT) * 140, 0),
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * searchT,
                        child: closeButton!,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_IOS26SliverAppBarDelegate oldDelegate) => true;
}

/// Hosts the bottom-slot widget: passes the slot's (shrinking) height
/// straight to the child — so a `fillHeight` native field physically
/// squeezes with the collapse, proportional to the scroll and the snap —
/// and intercepts taps at rest to trigger the morph.
///
/// Deliberately applies NO Flutter-side opacity: only the field's *content*
/// (text, hint, icons) fades, natively via [CupertinoSearchRowVisibility] —
/// never the capsule/glass container itself.
class _SearchSlot extends StatelessWidget {
  const _SearchSlot({
    required this.interactive,
    required this.onTap,
    required this.child,
  });

  final bool interactive;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget slot = ClipRect(child: child);
    if (!interactive) {
      slot = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AbsorbPointer(child: slot),
      );
    }
    return slot;
  }
}

/// One action as its own glass control: circle for icon-only, capsule
/// otherwise — sized like the iOS 26 system bars (44pt).
class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({required this.action, required this.labelStyle});

  final CupertinoAppBarAction action;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    if (action._isIconOnly) {
      return CupertinoNativeGlassContainer(
        shape: CupertinoNativeGlassShape.circle,
        interactive: true,
        width: 44,
        height: 44,
        // SwiftUI toolbar glyphs render ~20pt in the 44pt glass circle —
        // the global 17pt default looks undersized here.
        icon: action.icon!.withDefaultSize(20),
        onPressed: action.onPressed,
      );
    }
    return CupertinoNativeGlassContainer(
      shape: CupertinoNativeGlassShape.capsule,
      interactive: true,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onPressed: action.onPressed,
      child: action.child ?? Text(action.label!, style: labelStyle),
    );
  }
}

/// Adjacent label/child actions sharing one glass capsule — the
/// `glassEffectUnion` look of native toolbars.
class _GlassActionUnion extends StatelessWidget {
  const _GlassActionUnion({required this.actions, required this.labelStyle});

  final List<CupertinoAppBarAction> actions;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return CupertinoNativeGlassContainer(
      shape: CupertinoNativeGlassShape.capsule,
      interactive: true,
      childInteractive: true,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: actions[i].onPressed,
              child:
                  actions[i].child ??
                  Text(actions[i].label!, style: labelStyle),
            ),
          ],
        ],
      ),
    );
  }
}

/// The inline (non-collapsing) variant: a pinned 44pt bar floating on the
/// scroll-edge effect, with the same glass actions, title alignment and
/// subtitle. Place it in a `Stack` over your scrollable. Falls back to
/// [CupertinoNavigationBar] below iOS 26.
class CupertinoAppBar extends StatelessWidget {
  const CupertinoAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.centerTitle = true,
    this.leading,
    this.trailing = const [],
    this.separateTrailing = false,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.soft,
    this.tintColor,
  });

  final String title;
  final String? subtitle;
  final bool centerTitle;
  final CupertinoAppBarAction? leading;
  final List<CupertinoAppBarAction> trailing;
  final bool separateTrailing;
  final CupertinoNativeScrollEdgeEffect scrollEdgeEffect;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    if (!isIOS26OrLater) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading: leading == null
            ? null
            : GestureDetector(
                onTap: leading!.onPressed,
                child:
                    leading!.child ??
                    Text(
                      leading!.label ?? 'Back',
                      style: theme.textTheme.navActionTextStyle,
                    ),
              ),
      );
    }
    final topPadding = MediaQuery.paddingOf(context).top;
    final titleStyle = theme.textTheme.navTitleTextStyle.copyWith(
      decoration: TextDecoration.none,
    );
    final subtitleStyle = theme.textTheme.tabLabelTextStyle.copyWith(
      fontSize: 13,
      decoration: TextDecoration.none,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final actionStyle = theme.textTheme.textStyle.copyWith(
      decoration: TextDecoration.none,
    );

    final titleBlock = subtitle == null
        ? Text(title, style: titleStyle)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centerTitle
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              Text(subtitle!, style: subtitleStyle),
            ],
          );
    final leadingWidget = leading == null
        ? null
        : _GlassActionButton(action: leading!, labelStyle: actionStyle);
    final trailingWidgets = [
      for (var i = 0; i < trailing.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        _GlassActionButton(action: trailing[i], labelStyle: actionStyle),
      ],
    ];

    return SizedBox(
      height: topPadding + 44,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // Reaches past the bar's own bounds so the blur/tint fade out
          // instead of ending at the edge (see _effectOverhang).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                topPadding + 44 + _IOS26SliverAppBarDelegate._effectOverhang,
            child: RepaintBoundary(
              child: CupertinoScrollEdgeEffect(
                edge: CupertinoScrollEdgeEffectEdge.top,
                style: scrollEdgeEffect,
                color: tintColor,
              ),
            ),
          ),
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: 44,
            child: !centerTitle
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (leadingWidget != null) ...[
                          leadingWidget,
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: titleBlock,
                          ),
                        ),
                        ...trailingWidgets,
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      titleBlock,
                      if (leadingWidget != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: leadingWidget,
                          ),
                        ),
                      if (trailingWidgets.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: trailingWidgets,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
