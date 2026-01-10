class CupertinoNativeTab {
  final String title;
  final String? systemImage;
  final String id;
  // Optional: Badge count?

  const CupertinoNativeTab({
    required this.title,
    required this.id,
    this.systemImage,
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'systemImage': systemImage, 'id': id};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupertinoNativeTab &&
        other.title == title &&
        other.systemImage == systemImage &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(title, systemImage, id);
}
