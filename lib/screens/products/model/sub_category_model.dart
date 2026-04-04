class SubCategory {
  final int id;
  final String name;
  final String? categoryName;
  final String? designCode;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.designCode,
  });

  /// ✅ From JSON
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryName: json['category_name'] ?? '',
      designCode: json['design_code'] ?? '',
    );
  }

  /// ✅ To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'design_code': designCode,
    };
  }

  /// ✅ CopyWith
  SubCategory copyWith({
    int? id,
    String? name,
    String? categoryName,
    String? designCode,
  }) {
    return SubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      designCode: designCode ?? this.designCode,
    );
  }
}

class SubCategoryListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<SubCategory> results;

  SubCategoryListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  /// ✅ From JSON
  factory SubCategoryListResponse.fromJson(Map<String, dynamic> json) {
    var resultsList = json['results'] as List<dynamic>? ?? [];
    return SubCategoryListResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: resultsList.map((item) => SubCategory.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  /// ✅ To JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  /// ✅ CopyWith
  SubCategoryListResponse copyWith({
    int? count,
    String? next,
    String? previous,
    List<SubCategory>? results,
  }) {
    return SubCategoryListResponse(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}