import 'dart:ui' show Color;

/// An SF Symbol reference with optional point size and color.
class CupertinoNativeSymbol {
  final String name;
  final double? size;
  final Color? color;

  const CupertinoNativeSymbol(this.name, {this.size, this.color});

  Map<String, dynamic> toMap() {
    return {'name': name, 'size': size, 'color': color?.toARGB32()};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupertinoNativeSymbol &&
        other.name == name &&
        other.size == size &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(name, size, color);
}

/// An entry on the leading/trailing side of a [CupertinoNativeAppBar]:
/// either a single button ([CupertinoNativeBarItem]) or a group of buttons
/// sharing one glass capsule ([CupertinoNativeBarItemGroup]). Separate
/// entries render as separate capsules on iOS 26.
sealed class CupertinoNativeBarEntry {
  const CupertinoNativeBarEntry();

  Map<String, dynamic> toMap();
}

/// A single navigation-bar button. Provide an [icon], a [title], or both;
/// taps are reported through the app bar's `onAction` with [actionId].
class CupertinoNativeBarItem extends CupertinoNativeBarEntry {
  final String? title;
  final CupertinoNativeSymbol? icon;
  final String actionId;

  const CupertinoNativeBarItem({
    required this.actionId,
    this.title,
    this.icon,
  }) : assert(title != null || icon != null,
            'Provide a title, an icon, or both');

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'item',
      'title': title,
      'icon': icon?.toMap(),
      'actionId': actionId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupertinoNativeBarItem &&
        other.title == title &&
        other.icon == icon &&
        other.actionId == actionId;
  }

  @override
  int get hashCode => Object.hash(title, icon, actionId);
}

/// Several buttons rendered inside ONE shared glass capsule (like the
/// segmented trailing buttons in iOS 26 system apps). Use separate
/// [CupertinoNativeBarItem] entries instead when each button should get its
/// own capsule.
class CupertinoNativeBarItemGroup extends CupertinoNativeBarEntry {
  final List<CupertinoNativeBarItem> items;

  const CupertinoNativeBarItemGroup({required this.items});

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'group',
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}
