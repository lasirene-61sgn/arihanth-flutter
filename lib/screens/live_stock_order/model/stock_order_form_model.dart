class StockOrderFormModel {
  final bool? success;
  final FormProduct? product;

  StockOrderFormModel({this.success, this.product});

  factory StockOrderFormModel.fromJson(Map<String, dynamic> json) {
    return StockOrderFormModel(
      success: json['success'],
      product: json['product'] != null ? FormProduct.fromJson(json['product']) : null,
    );
  }
}

class FormProduct {
  final int? id;
  final String? designCode;
  final String? productName;
  final String? category;
  final String? subcategory;
  final String? weightFrom;
  final String? weightTo;
  final String? size;
  final String? image;
  final String? imageRaw;

  FormProduct({
    this.id,
    this.designCode,
    this.productName,
    this.category,
    this.subcategory,
    this.weightFrom,
    this.weightTo,
    this.size,
    this.image,
    this.imageRaw,
  });

  factory FormProduct.fromJson(Map<String, dynamic> json) {
    return FormProduct(
      id: json['id'],
      designCode: json['design_code']?.toString(),
      productName: json['product_name']?.toString(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      weightFrom: json['weight_from']?.toString(),
      weightTo: json['weight_to']?.toString(),
      size: json['size']?.toString(),
      image: json['image']?.toString(),
      imageRaw: json['image_raw']?.toString(),
    );
  }
}
