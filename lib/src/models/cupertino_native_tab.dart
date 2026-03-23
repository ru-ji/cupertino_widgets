enum CupertinoNativeTabRole { search }

class CupertinoNativeTab {
  final String title;
  final String? systemImage;
  final String id;
  final CupertinoNativeTabRole? role;
  // Optional: Badge count?

  const CupertinoNativeTab({
    required this.title,
    required this.id,
    this.systemImage,
    this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'systemImage': systemImage,
      'id': id,
      'role': role?.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupertinoNativeTab &&
        other.title == title &&
        other.systemImage == systemImage &&
        other.id == id &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(title, systemImage, id, role);
}
