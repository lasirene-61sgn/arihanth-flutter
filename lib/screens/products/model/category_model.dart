class Category {
  final int id;
  final String name;
  final bool hasHook;
  final bool hasEnamel;
  final bool hasRodium;
  final bool hasOpenClose;
  final bool hasStone;

  Category({
    required this.id,
    required this.name,
    this.hasHook = false,
    this.hasEnamel = false,
    this.hasRodium = false,
    this.hasOpenClose = false,
    this.hasStone = false,
  });

  /// ✅ From JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      hasHook: json['has_hook'] ?? true, // Maps "has_hook"
      hasEnamel: json['has_enamel'] ?? true, // Maps "has_enamel"
      hasRodium: json['has_rodium'] ?? true, // Maps "has_rodium"
      hasOpenClose: json['has_open_close'] ?? true, // Maps "has_open_close"
      hasStone: json['has_stone'] ?? true, // Maps "has_stone"
    );
  }

  /// ✅ To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'has_hook': hasHook,
      'has_enamel': hasEnamel,
      'has_rodium': hasRodium,
      'has_open_close': hasOpenClose,
      'has_stone': hasStone,
    };
  }

  /// ✅ CopyWith
  Category copyWith({
    int? id,
    String? name,
    bool? hasHook,
    bool? hasEnamel,
    bool? hasRodium,
    bool? hasOpenClose,
    bool? hasStone,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      hasHook: hasHook ?? this.hasHook,
      hasEnamel: hasEnamel ?? this.hasEnamel,
      hasRodium: hasRodium ?? this.hasRodium,
      hasOpenClose: hasOpenClose ?? this.hasOpenClose,
      hasStone: hasStone ?? this.hasStone,
    );
  }
}