import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import 'cupertino_native_glass_container.dart';
import 'cupertino_native_tab_bar.dart' show CupertinoNativeScrollEdgeEffect;
import 'cupertino_scroll_edge_effect.dart';
import 'internal/ios_version.dart';
import 'models/cupertino_native_icon.dart';
import 'models/cupertino_symbols.dart';

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
  }) : assert(icon != null || label != null || child != null,
            'Provide an icon, a label, or a child');

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

/// Where the inline title sits in the bar.
enum CupertinoAppBarTitleAlignment { center, leading }

/// An iOS 26-style navigation bar drawn in Flutter.
///
/// SwiftUI's navigation title can't be hosted standalone in Flutter, so these
/// widgets recreate the iOS 26 look: no solid background or hairline — the
/// bar floats on a [CupertinoScrollEdgeEffect]; the large title collapses
/// with the system blur-morph; [leading]/[trailing] are Liquid Glass buttons
/// ([CupertinoAppBarAction]); the title can sit centered or [titleAlignment]
/// leading with an optional [subtitle]; and an optional [searchField] morphs
/// into a docked search bar with a glass ✕.
///
/// The search API mirrors Flutter's [CupertinoSliverNavigationBar.search]:
/// [searchField] is **any widget** (typically a `CupertinoNativeTextField`),
/// and [bottomMode] decides whether it collapses with the scroll
/// ([NavigationBarBottomMode.automatic], the default — the search row is
/// consumed *before* the page starts scrolling, shrinking and fading to
/// nothing) or stays visible ([NavigationBarBottomMode.always]).
///
/// Below iOS 26 it falls back to Flutter's [CupertinoSliverNavigationBar]
/// (using its `.search` variant when [searchField] is set).
class CupertinoSliverAppBar extends StatefulWidget {
  const CupertinoSliverAppBar({
    super.key,
    required this.largeTitle,
    this.subtitle,
    this.titleAlignment = CupertinoAppBarTitleAlignment.center,
    this.expandedTitle = true,
    this.leading,
    this.trailing = const [],
    this.separateTrailing = false,
    this.searchField,
    this.bottomMode = NavigationBarBottomMode.automatic,
    this.onSearchActiveChanged,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.soft,
    this.tintColor,
  });

  final String largeTitle;

  /// Whether the expanded (large) title row exists. When false the bar is
  /// inline-only: the title is always in the bar and nothing collapses.
  final bool expandedTitle;

  /// Secondary line — under the large title (like Photos' "3,356 Items") and
  /// under the inline title when collapsed.
  final String? subtitle;

  /// Inline-title placement: centered (default) or right after [leading].
  final CupertinoAppBarTitleAlignment titleAlignment;

  final CupertinoAppBarAction? leading;

  /// Trailing actions. Icon-only actions always get their own glass circle;
  /// label/child actions share one capsule (the `glassEffectUnion` look)
  /// unless [separateTrailing] is true.
  final List<CupertinoAppBarAction> trailing;

  final bool separateTrailing;

  /// The search field widget shown under the large title — same contract as
  /// [CupertinoSliverNavigationBar.search]. Tapping it triggers the morph:
  /// the field docks to the top, narrowing while a glass ✕ rides in from the
  /// right screen edge. Manage focus from [onSearchActiveChanged] (e.g.
  /// request focus on your field's `focusNode` when it activates).
  final Widget? searchField;

  /// Whether the search row collapses with the scroll (`automatic`) or stays
  /// visible (`always`).
  final NavigationBarBottomMode bottomMode;

  /// Fires when the search activates/deactivates, so the page can swap its
  /// content for a search view and manage the field's focus.
  final ValueChanged<bool>? onSearchActiveChanged;

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
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _searchT =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSearchActive(bool active) {
    if (active) {
      _controller.forward();
    } else {
      _controller.reverse();
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
      if (widget.searchField != null) {
        return CupertinoSliverNavigationBar.search(
          searchField: widget.searchField!,
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
    final actionStyle =
        theme.textTheme.textStyle.copyWith(decoration: TextDecoration.none);
    final leading = widget.leading == null
        ? null
        : _GlassActionButton(action: widget.leading!, labelStyle: actionStyle);
    final trailing = _buildTrailing(actionStyle);
    final closeButton = widget.searchField == null
        ? null
        : CupertinoNativeGlassContainer(
            shape: CupertinoNativeGlassShape.circle,
            interactive: true,
            width: 44,
            height: 44,
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.xmark),
            onPressed: () => _setSearchActive(false),
          );

    return AnimatedBuilder(
      animation: _searchT,
      builder: (context, _) => SliverPersistentHeader(
        pinned: true,
        delegate: _IOS26SliverAppBarDelegate(
          largeTitle: widget.largeTitle,
          subtitle: widget.subtitle,
          titleAlignment: widget.titleAlignment,
          expandedTitle: widget.expandedTitle,
          leading: leading,
          trailing: trailing,
          searchField: widget.searchField,
          bottomMode: widget.bottomMode,
          closeButton: closeButton,
          edgeEffect: edgeEffect,
          searchT: _searchT.value,
          onSearchOpen: () => _setSearchActive(true),
          topPadding: MediaQuery.paddingOf(context).top,
          // Native Flutter Cupertino nav bar text styles.
          inlineTitleStyle: theme.textTheme.navTitleTextStyle
              .copyWith(decoration: TextDecoration.none),
          largeTitleStyle: theme.textTheme.navLargeTitleTextStyle
              .copyWith(decoration: TextDecoration.none),
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
              _GlassActionButton(action: action, labelStyle: labelStyle));
        }
      } else {
        children.add(_GlassActionUnion(
            actions: List.of(grouped), labelStyle: labelStyle));
      }
      grouped.clear();
    }

    for (final action in widget.trailing) {
      if (action._isIconOnly || widget.separateTrailing) {
        flushGroup();
        children
            .add(_GlassActionButton(action: action, labelStyle: labelStyle));
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
      child: action.child ??
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
    required this.titleAlignment,
    required this.expandedTitle,
    required this.leading,
    required this.trailing,
    required this.searchField,
    required this.bottomMode,
    required this.closeButton,
    required this.edgeEffect,
    required this.searchT,
    required this.onSearchOpen,
    required this.topPadding,
    required this.inlineTitleStyle,
    required this.largeTitleStyle,
    required this.subtitleStyle,
  });

  // Geometry mirrors Flutter's CupertinoSliverNavigationBar:
  // _kNavBarLargeTitleHeightExtension = 52, _kNavBarBottomPadding = 8,
  // _kSearchFieldHeight = 36.
  static const double _barH = 44;
  static const double _largeExtension = 52;
  static const double _bottomPadding = 8;
  static const double _fieldH = 36;
  static const double _searchRowH = _fieldH + _bottomPadding + 6;

  final String largeTitle;
  final String? subtitle;
  final CupertinoAppBarTitleAlignment titleAlignment;
  final bool expandedTitle;
  final Widget? leading;
  final Widget? trailing;

  /// User-provided field, permanently mounted (platform views must never be
  /// created mid-animation) and hosted in the traveling/collapsing slot.
  final Widget? searchField;
  final NavigationBarBottomMode bottomMode;
  final Widget? closeButton;
  final Widget edgeEffect;

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
  double get _largeH =>
      !expandedTitle ? 0 : (subtitle == null ? _largeExtension : _largeExtension + 20);

  double get _restingMax =>
      topPadding + _barH + _largeH + (_hasSearch ? _searchRowH : 0);
  double get _restingMin =>
      topPadding +
      _barH +
      (_hasSearch && bottomMode == NavigationBarBottomMode.always
          ? _searchRowH
          : 0);
  double get _activeExtent => topPadding + _fieldH + 12;

  @override
  double get minExtent => ui.lerpDouble(_restingMin, _activeExtent, searchT)!;

  @override
  double get maxExtent {
    final value = ui.lerpDouble(_restingMax, _activeExtent, searchT)!;
    return value < minExtent ? minExtent : value;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final height = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    // Sequenced collapse, like Flutter's bottomMode.automatic: the scroll
    // consumes the search row FIRST (it shrinks and fades to nothing before
    // the page moves), then the large title collapses.
    final consumedBySearch =
        _collapsibleSearch ? shrinkOffset.clamp(0.0, _searchRowH) : 0.0;
    final searchCollapseT =
        _collapsibleSearch ? consumedBySearch / _searchRowH : 0.0;
    final titleShrink = shrinkOffset - consumedBySearch;
    final tTitle =
        _largeH <= 0 ? 1.0 : (titleShrink / _largeH).clamp(0.0, 1.0);

    final largeOpacity = !expandedTitle
        ? 0.0
        : (1 - tTitle / 0.75).clamp(0.0, 1.0) * (1 - searchT);
    // The collapsed (inline) title appears only as the large title collapses
    // on scroll — or permanently when the expanded title is disabled.
    final inlineT =
        !expandedTitle ? 1.0 : ((tTitle - 0.55) / 0.45).clamp(0.0, 1.0);
    final chrome = (1 - searchT * 1.6).clamp(0.0, 1.0);
    final inlineSigma = (1 - inlineT) * 8;

    // Search slot geometry: shrinks with the collapse, travels on activation.
    final restFieldH = _fieldH * (1 - searchCollapseT);
    final fieldH =
        ui.lerpDouble(restFieldH, _fieldH, searchT)!.clamp(0.1, _fieldH);
    final restTop = height - restFieldH - _bottomPadding * (1 - searchCollapseT);
    final fieldTop = ui.lerpDouble(restTop, topPadding + 4, searchT)!;
    // The field narrows as it rises, making room for the ✕.
    final fieldRight = ui.lerpDouble(16, 16 + 44 + 12, searchT)!;
    final contentFade =
        searchT > 0 ? 1.0 : (1 - searchCollapseT * 1.3).clamp(0.0, 1.0);

    Widget inlineTitleBlock = subtitle == null
        ? Text(largeTitle, style: inlineTitleStyle)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                titleAlignment == CupertinoAppBarTitleAlignment.leading
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
            children: [
              Text(largeTitle, style: inlineTitleStyle),
              Text(subtitle!, style: subtitleStyle),
            ],
          );
    // Blur-morph + translate-from-below, like the system collapse.
    inlineTitleBlock = Opacity(
      opacity: inlineT * chrome,
      child: Transform.translate(
        offset: Offset(0, (1 - inlineT) * 16),
        child: inlineSigma > 0.1
            ? ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                    sigmaX: inlineSigma, sigmaY: inlineSigma),
                child: inlineTitleBlock,
              )
            : inlineTitleBlock,
      ),
    );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: edgeEffect),
          // Inline bar row. Slides up out of view during the search morph
          // (platform views can't be opacity-faded).
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: _barH,
            child: Transform.translate(
              offset: Offset(0, -(1 - chrome) * (topPadding + _barH)),
              child: titleAlignment == CupertinoAppBarTitleAlignment.leading
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
            bottom: (_hasSearch
                    ? _searchRowH *
                        (bottomMode == NavigationBarBottomMode.always
                            ? 1.0
                            : (1 - searchCollapseT))
                    : 0) +
                _bottomPadding,
            child: Opacity(
              opacity: largeOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    largeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: largeTitleStyle,
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: subtitleStyle),
                ],
              ),
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
                fade: contentFade,
                fieldHeight: _fieldH,
                interactive: searchT > 0.05,
                onTap: onSearchOpen,
                child: searchField!,
              ),
            ),
            // Glass ✕ — permanently mounted; rides in from beyond the right
            // screen edge, scaling up as it materializes next to the field.
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
    );
  }

  @override
  bool shouldRebuild(_IOS26SliverAppBarDelegate oldDelegate) => true;
}

/// Hosts the user's search field: keeps its natural height inside the
/// shrinking slot (clipped), fades drawn content on collapse, and intercepts
/// taps at rest to trigger the morph.
class _SearchSlot extends StatelessWidget {
  const _SearchSlot({
    required this.fade,
    required this.fieldHeight,
    required this.interactive,
    required this.onTap,
    required this.child,
  });

  final double fade;
  final double fieldHeight;
  final bool interactive;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget slot = ClipRect(
      child: OverflowBox(
        maxHeight: fieldHeight,
        minHeight: 0,
        alignment: Alignment.topCenter,
        child: SizedBox(height: fieldHeight, child: child),
      ),
    );
    if (fade < 1) {
      slot = Opacity(opacity: fade, child: slot);
    }
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
        icon: action.icon,
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
              child: actions[i].child ??
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
    this.titleAlignment = CupertinoAppBarTitleAlignment.center,
    this.leading,
    this.trailing = const [],
    this.separateTrailing = false,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.soft,
    this.tintColor,
  });

  final String title;
  final String? subtitle;
  final CupertinoAppBarTitleAlignment titleAlignment;
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
                child: leading!.child ??
                    Text(leading!.label ?? 'Back',
                        style: theme.textTheme.navActionTextStyle),
              ),
      );
    }
    final topPadding = MediaQuery.paddingOf(context).top;
    final titleStyle = theme.textTheme.navTitleTextStyle
        .copyWith(decoration: TextDecoration.none);
    final subtitleStyle = theme.textTheme.tabLabelTextStyle.copyWith(
      fontSize: 13,
      decoration: TextDecoration.none,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final actionStyle =
        theme.textTheme.textStyle.copyWith(decoration: TextDecoration.none);

    final titleBlock = subtitle == null
        ? Text(title, style: titleStyle)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                titleAlignment == CupertinoAppBarTitleAlignment.leading
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
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
        fit: StackFit.expand,
        children: [
          Positioned.fill(
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
            child: titleAlignment == CupertinoAppBarTitleAlignment.leading
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
