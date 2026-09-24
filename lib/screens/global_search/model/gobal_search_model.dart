class GlobalSearchModel {
  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? status;
  final List<dynamic>? items;
  final Map<String, dynamic> rawData;

  GlobalSearchModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.status,
    this.items,
    required this.rawData,
  });

  factory GlobalSearchModel.fromJson(Map<String, dynamic> json, String type) {
    // Attempt to dynamically resolve the best title/subtitle based on available keys
    final title = json['product_code'] ?? json['work_order_number'] ?? json['purchase_order_code'] ?? json['order_no'] ?? json['design_code'] ?? json['product_name'] ?? json['design_name'] ?? json['name'] ?? json['title'] ?? 'Unknown';
    final subtitle = (title == json['product_name'] || title == json['design_name']) 
        ? '' 
        : (json['product_name'] ?? json['design_name'] ?? json['description'] ?? '');

    return GlobalSearchModel(
      id: json['id'] ?? 0,
      type: type,
      title: title.toString(),
      subtitle: subtitle.toString(),
      imageUrl: json['product_image_url'] ?? json['preview_image_url'] ?? json['image_proof_url'] ?? json['image'] ?? json['product_image'] ?? json['image_proof'],
      status: json['status']?.toString(),
      items: json['items'] as List<dynamic>?,
      rawData: json,
    );
  }

  GlobalSearchModel copyWith({
    int? id,
    String? type,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? status,
    List<dynamic>? items,
    Map<String, dynamic>? rawData,
  }) {
    return GlobalSearchModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      items: items ?? this.items,
      rawData: rawData ?? this.rawData,
    );
  }
}
