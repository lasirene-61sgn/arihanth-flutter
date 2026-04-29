// Updated ProductListNotifier
import 'dart:convert';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/model/category_model.dart';
import 'package:arianth/screens/products/model/products_model.dart';
import 'package:arianth/screens/products/model/sub_category_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/legacy.dart';

const _sentinel = Object();

class ProductListState {
  final bool isLoading;
  final bool isLoaded;
  final bool isSaving;
  final bool isAccepting; // New
  final bool isRejecting;
  final bool isSaved; // ✅ New flag
  final bool isLoadingBp; // ✅ New flag
  final bool isBulkUploading;
  final String? error;
  final List<Product> products;
  final List<Product> allProducts;
  final List<Product> workOrderProduct;
  final List<BpBuyerModel> bpBuyerList;
  final List<BpBuyerModel> bpCraftsmanList;
  final Product? productDetail; // ✅ Added product detail state

  // ✅ Separate states for categories
  final bool isLoadingCategories;
  final List<Category> categories;
  final String? errorCategories;
  final bool isSavingCategories;
  final bool isSavedCategories;

  // ✅ Separate states for subcategories
  final bool isLoadingSubCategories;
  final List<SubCategory> subCategories;
  final String? errorSubCategories;
  final bool isSavingSubCategories;
  final bool isSavedSubCategories;
  final int count;
  final String? nextUrl;
  final String? lastUrl;
  final String? previousUrl;

  const ProductListState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isSaving = false,
    this.isLoadingBp = false,
    this.isAccepting = false, // Initialize
    this.isRejecting = false,
    this.isSaved = false, // ✅ initialize
    this.isBulkUploading = false,
    this.error,
    this.products = const [],
    this.allProducts = const [],
    this.workOrderProduct = const [],
    this.bpBuyerList = const [],
    this.bpCraftsmanList = const [],
    this.productDetail,
    // ✅ Initialize category states
    this.isLoadingCategories = false,
    this.categories = const [],
    this.errorCategories,
    this.isSavingCategories = false,
    this.isSavedCategories = false,
    // ✅ Initialize subcategory states
    this.isLoadingSubCategories = false,
    this.subCategories = const [],
    this.errorSubCategories,
    this.isSavingSubCategories = false,
    this.isSavedSubCategories = false,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
    this.lastUrl,
  });

  ProductListState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isSaving,
    bool? isAccepting,
    bool? isRejecting,
    bool? isSaved,
    bool? isLoadingBp,
    bool? isBulkUploading,
    dynamic error = _sentinel,
    List<Product>? products,
    List<Product>? allProducts,
    List<Product>? workOrderProduct,
    List<BpBuyerModel>? bpBuyerList,
    List<BpBuyerModel>? bpCraftsmanList,
    // 🛠️ FIX: Sentinel for productDetail
    dynamic productDetail = _sentinel,
    bool clearProductDetail = false,
    // ✅ Add copyWith params for categories
    bool? isLoadingCategories,
    List<Category>? categories,
    String? errorCategories,
    bool? isSavingCategories,
    bool? isSavedCategories,
    // ✅ Add copyWith params for subcategories
    bool? isLoadingSubCategories,
    List<SubCategory>? subCategories,
    String? errorSubCategories,
    bool? isSavingSubCategories,
    bool? isSavedSubCategories,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    dynamic lastUrl = _sentinel,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      isAccepting: isAccepting ?? this.isAccepting,
      isRejecting: isRejecting ?? this.isRejecting,
      isLoadingBp: isLoadingBp ?? this.isLoadingBp,
      isBulkUploading: isBulkUploading ?? this.isBulkUploading,
      workOrderProduct: workOrderProduct ?? this.workOrderProduct,
      isSaved: isSaved ?? this.isSaved,
      error: error == _sentinel ? this.error : error as String?,
      products: products ?? this.products,
      bpBuyerList: bpBuyerList ?? this.bpBuyerList,
      bpCraftsmanList: bpCraftsmanList ?? this.bpCraftsmanList,
      allProducts: allProducts ?? this.allProducts,
      // 🛠️ FIX: Apply the sentinel check
      productDetail: clearProductDetail ? null : (productDetail == _sentinel ? this.productDetail : productDetail as Product?),
      // ✅ Copy category states
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      categories: categories ?? this.categories,
      errorCategories: errorCategories ?? this.errorCategories,
      isSavingCategories: isSavingCategories ?? this.isSavingCategories,
      isSavedCategories: isSavedCategories ?? this.isSavedCategories,
      // ✅ Copy subcategory states
      isLoadingSubCategories: isLoadingSubCategories ?? this.isLoadingSubCategories,
      subCategories: subCategories ?? this.subCategories,
      errorSubCategories: errorSubCategories ?? this.errorSubCategories,
      isSavingSubCategories: isSavingSubCategories ?? this.isSavingSubCategories,
      isSavedSubCategories: isSavedSubCategories ?? this.isSavedSubCategories,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      lastUrl: lastUrl == _sentinel ? this.lastUrl : lastUrl as String?,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier() : super(const ProductListState());

  /// Fetch the list of products from API
  Future<void> fetchProducts({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: url ?? "api/common/products");




      // Check if API returned status=1 and has nested data
      if (response["status"] == 1 &&
          response["data"] != null &&
          response["data"]["data"] != null &&
          response["data"]["data"]["data"] is List) {

        final List<dynamic> productList = response["data"]["data"]["data"];
        final int newCount = response["data"]["data"]["total"] ?? productList.length;
        final String? newNext = response["data"]["data"]["next_page_url"];
        final String? newPrevious = response["data"]["data"]["prev_page_url"];
        final String? relativeUrl = url != null ? ApiClient.toRelativeUrl(url) : null;

        final products = productList.map((item) => Product.fromJson(item)).toList();



        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          products: products,
          allProducts: products,
          count: newCount,
          nextUrl: newNext,
          previousUrl: newPrevious,
          lastUrl: relativeUrl,
        );
      } else {

        state = state.copyWith(
          isLoading: false,
          isLoaded: false,
        );
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: "Failed to load products: ${e.toString()}",
      );
    }
  }
  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      print('next -> $relativeUrl');
      state = state.copyWith(products: []);
      fetchProducts(url: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      state = state.copyWith(products: []);
      fetchProducts(url: relativeUrl);
    }
  }
  Future<void> fetchCategories({String? url}) async {
    state = state.copyWith(isLoadingCategories: true, errorCategories: null);

    try {
      // Calling the super-admin endpoint
      final response = await ApiClient().get(
          endpoint: url ?? "api/common/products/categories"
      );



      // Unwrap the status layer: {status: 1, data: {success: true, data: [...]}}
      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];

        if (actualResponse != null && actualResponse["success"] == true) {
          // DIRECT CALL: Access the list from the 'data' key and map to Category objects
          final List<dynamic> rawData = actualResponse["data"] ?? [];

          final List<Category> categories = rawData
              .map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList();



          state = state.copyWith(
            isLoadingCategories: false,
            categories: categories,
          );
        } else {
          throw Exception(actualResponse?["message"] ?? 'API success check failed');
        }
      } else {
        throw Exception(response?["message"] ?? 'Invalid status from server');
      }
    } catch (e, stackTrace) {


      state = state.copyWith(
        isLoadingCategories: false,
        errorCategories: "Failed to load categories: ${e.toString()}",
      );
    }
  }
  Future<void> fetchBPCodes() async {
    state = state.copyWith(isLoadingBp: true, errorCategories: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/work-orders/helpers/bp-codes");


      // 1. Check for Top-level status
      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"]; // {success: true, data: [...]}

        // 2. Check for the nested list inside actualResponse['data']
        if (actualResponse != null &&
            actualResponse["data"] != null &&
            actualResponse["data"] is List) {

          final List<dynamic> rawList = actualResponse["data"];

          final List<BpBuyerModel> bpCodes = rawList
              .map((item) => BpBuyerModel.fromJson(item))
              .toList();



          state = state.copyWith(
            isLoadingBp: false,
            bpBuyerList: bpCodes,
          );
        } else {
          throw Exception('BP list not found in the data payload');
        }
      } else {
        throw Exception(response?["message"] ?? 'API status failure');
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoadingBp: false,
        errorCategories: "Failed to load BP Codes: ${e.toString()}",
      );
    }
  }
  Future<void> fetchCraftBPCodes() async {
    state = state.copyWith(isLoadingBp: true, errorCategories: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/work-orders/helpers/craftman-codes");


      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];

        if (actualResponse != null &&
            actualResponse["data"] != null &&
            actualResponse["data"] is List) {

          final List<dynamic> rawList = actualResponse["data"];

          final List<BpBuyerModel> bpCodes = rawList
              .map((item) => BpBuyerModel.fromJson(item))
              .toList();

          print("Fetched craftsman Codes cR: ${bpCodes.length} items");

          state = state.copyWith(
            isLoadingBp: false,
            bpCraftsmanList: bpCodes,
          );
        } else {
          state = state.copyWith(
            isLoadingBp: false,
            errorCategories: 'BP Codes API returned empty or invalid list',
          );
        }
      } else {
        state = state.copyWith(
          isLoadingBp: false,
          errorCategories: response?["message"] ?? 'API status failure',
        );
      }

    } catch (e, stackTrace) {
      print("BP Codes fetch error: ${e.toString()}");
      print("Stack trace: $stackTrace");

      state = state.copyWith(
        isLoadingBp: false,
        errorCategories: "Failed to load BP Codes: ${e.toString()}",
      );
    }
  }


  // ✅ New method: Fetch subcategories with separate loader
  Future<List<SubCategory>> fetchSubCategories({String? url}) async {
    state = state.copyWith(
      isLoadingSubCategories: true,
      errorSubCategories: null,
      subCategories: [], // Clear stale subcategories
    );

    try {
      final response = await ApiClient().get(endpoint: url ?? "");

      print("++++ SubCategories API Response: $response");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        if (actualResponse != null && actualResponse["success"] == true) {
          final List<dynamic> rawData = actualResponse["data"] ?? [];
          
          final List<SubCategory> subCategories = rawData
              .map((item) => SubCategory.fromJson(item as Map<String, dynamic>))
              .toList();

          state = state.copyWith(
            isLoadingSubCategories: false,
            subCategories: subCategories,
          );
          return subCategories;
        } else {
          throw Exception(actualResponse?["message"] ?? 'API success check failed');
        }
      } else {
        throw Exception(response?["message"] ?? 'Invalid response format');
      }
    } catch (e, stackTrace) {
      print("SubCategories fetch error: ${e.toString()}");
      print("Stack trace: $stackTrace");

      state = state.copyWith(
        isLoadingSubCategories: false,
        errorSubCategories: "Failed to load subcategories: ${e.toString()}",
      );
      return [];
    }
  }

  // ✅ Updated method: Save category (POST with {"name": name}), returns saved category
// ✅ Updated method: Save category via super-admin API
  Future<Category?> saveCategory(
      String name, {
        String? url,
        bool hasHook = false,
        bool hasEnamel = false,
        bool hasRodium = false,
        bool hasOpenClose = false,
        bool hasStone = false,
      }) async {
    // 1. Initial Loading State
    state = state.copyWith(
      isSavingCategories: true,
      isSavedCategories: false,
      errorCategories: null,
    );

    try {
      final endpoint = url ?? 'api/common/products/categories';
      final Map<String, dynamic> payload = {
        "name": name,
        "has_hook": hasHook,
        "has_enamel": hasEnamel,
        "has_rodium": hasRodium,
        "has_open_close": hasOpenClose,
        "has_stone": hasStone,
      };

      final response = await ApiClient().post(
        endpoint: endpoint,
        body: payload,
      );

      // 2. Handle Logic Success (Status 1)
      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];

        if (actualResponse != null && actualResponse["success"] == true) {
          final nestedData = actualResponse["data"];
            await fetchCategories();
          if (nestedData != null && nestedData["category"] != null) {
            final savedCategory = Category.fromJson(nestedData["category"]);

            state = state.copyWith(
              isSavingCategories: false,
              isSavedCategories: true,
              categories: [...state.categories, savedCategory],
            );
            return savedCategory;
          }
        }

        // 3. Handle Logical Failure (e.g., Validation Error)
        // Instead of throw, we set the state
        state = state.copyWith(
          isSavingCategories: false,
          isSavedCategories: false,
          errorCategories: actualResponse?["message"] ?? "Failed to create category",
        );
        return null;

      } else {
        // 4. Handle Server/Status Failure (Status 0 or null)
        state = state.copyWith(
          isSavingCategories: false,
          isSavedCategories: false,
          errorCategories: response?["message"] ?? "Server communication failed",
        );
        return null;
      }

    } catch (e, st) {

      state = state.copyWith(
        isSavingCategories: false,
        isSavedCategories: false,
        errorCategories: "Connection error: ${e.toString()}",
      );
      return null;
    }
  }

  // ✅ New method: Add category to local list
  void addCategory(Category category) {
    state = state.copyWith(
      categories: [...state.categories, category],
    );
  }

  // ✅ Updated method: Save subcategory via API
  Future<SubCategory?> saveSubCategory(
      String name,
      {String? urls,
        String? category,
        int? categoryId,}
      ) async {
    state = state.copyWith(isSavingSubCategories: true, isSavedSubCategories: false, errorSubCategories: null);

    try {
      // Use the provided url or construct it if categoryId is available
      final url = urls ?? (categoryId != null ? 'api/common/products/subcategories' : '');
      final map = {
        "product_category_id":categoryId,
        "name":name
      }; // Category ID is implicitly handled by the URL or backend config

      final response = await ApiClient().post(endpoint: url, body: map);

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        if (actualResponse != null && actualResponse["success"] == true) {
           final nestedData = actualResponse["data"];
           // Check if it returns a specific subcategory object or we construct it manually since it was successful
           SubCategory? savedSubCategory;
           if (nestedData != null && nestedData["id"] != null) {
             savedSubCategory = SubCategory.fromJson(nestedData);
           } else {
             // Fallback
             savedSubCategory = SubCategory(id: DateTime.now().millisecondsSinceEpoch, name: name, categoryName: category, designCode: '');
           }
           
           state = state.copyWith(
             isSavingSubCategories: false,
             isSavedSubCategories: true,
           );
           return savedSubCategory;
        } else {
          throw Exception(actualResponse?["message"] ?? 'Failed to save subcategory');
        }
      } else {
         throw Exception(response?["message"] ?? 'Server status failed');
      }
    } catch (e, stackTrace) {
      print("SubCategory save error: $e");
      state = state.copyWith(
        isSavingSubCategories: false,
        isSavedSubCategories: false,
        errorSubCategories: e.toString(),
      );
    }
    return null;
  }

  // ✅ New method: Add subcategory to local list
  void addSubCategory(SubCategory subCategory) {
    state = state.copyWith(
      subCategories: [...state.subCategories, subCategory],
    );
  }

  Future<void> saveProduct(
      Map<String, dynamic> map, {
        String? id,
        Map<String, dynamic>? files,
        String fileKey = 'product_image',
      }) async {
    state = state.copyWith(isSaving: true, isSaved: false, error: null);

    try {
      final bool isUpdate = id != null && id.isNotEmpty && id != "null";
      final String method = isUpdate ? "POST" : "POST";
      final String endpoint = isUpdate ? "api/common/products/$id" : "api/common/products";

      final response = await ApiClient().requestWithFiles(
        method: method,
        endpoint: endpoint,
        fields: map,
        files: files,
      );


      if (response["status"] == 1 && response["data"] != null) {
        Toaster.showSuccess(isUpdate ? "Product updated successfully" : "Product created successfully");
        await fetchProducts();
        Get.back();
        state = state.copyWith(
          isSaving: false,
          isSaved: true,
          clearProductDetail: true,
        );
      } else {
        final errorMsg = _extractErrorMessage(response["message"]);
        Toaster.showError(errorMsg);
        state = state.copyWith(
          isSaving: false,
          isSaved: false,
          error: errorMsg,
        );
      }
    } catch (e, stackTrace) {

      final errorMsg = e.toString();
      Toaster.showError(errorMsg);
      state = state.copyWith(
        isSaving: false,
        isSaved: false,
        error: errorMsg,
      );
    }
  }

  String _extractErrorMessage(dynamic message) {
    if (message is Map) {
      if (message.containsKey('errors')) {
        final errors = message['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          return firstError.toString();
        }
      }
      if (message.containsKey('message')) {
        return message['message'].toString();
      }
    }
    return message?.toString() ?? "An unexpected error occurred";
  }
  Future<void> forAction(
      Map<String, dynamic> map, {
        String? id,
        bool? reject, // true = Rejecting, false/null = Accepting
        PlatformFile? file,
        String fileKey = 'product_image',
      }) async {
    // Set specific loading states based on the 'reject' flag
    state = state.copyWith(
      isRejecting: reject == true,
      isAccepting: reject != true,
      isSaved: false,
      error: null,
    );

    try {
      final bool isUpdate = id != null && id.isNotEmpty && id != "null";
      final String method = isUpdate ? "PUT" : "POST";
      final String endpoint = isUpdate ? "api/common/products/$id" : "api/common/products";

      final response = await ApiClient().requestWithFiles(
        method: method,
        endpoint: endpoint,
        fields: map,
        files: file != null ? {fileKey: file} : null,
      );
print("Edit this product_______$response");
      if (response["status"] == 1 && response["data"] != null) {
        Toaster.showSuccess(reject == true ? "Action rejected successfully" : "Action accepted successfully");
        await fetchProducts();
        Get.back();
        state = state.copyWith(
          isRejecting: false,
          isAccepting: false,
          isSaved: true,
          clearProductDetail: true,
        );
      } else {
        final errorMsg = _extractErrorMessage(response["message"]);
        Toaster.showError(errorMsg);
        state = state.copyWith(
          isRejecting: false,
          isAccepting: false,
          isSaved: false,
          error: errorMsg,
        );
      }
    } catch (e, stackTrace) {

      final errorMsg = e.toString();
      Toaster.showError(errorMsg);
      state = state.copyWith(
        isRejecting: false,
        isAccepting: false,
        isSaved: false,
        error: errorMsg,
      );
    }
  }

  void clearProductDetail() {
    // 🛠️ FIX: Use the flag to explicitly clear
    state = state.copyWith(clearProductDetail: true);
  }
  Future<void> productDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(
          endpoint: "api/common/products/$id");

      // Grab the first "data" object which contains "success" and the inner "data"
      final responseData = response["data"];



      // Check if responseData exists, success is true, and the inner data exists
      if (responseData != null && responseData["success"] == true && responseData["data"] != null) {

        // Extract the actual product map
        final actualProductData = responseData["data"];

        final productDetail = Product.fromJson(actualProductData);

        state = state.copyWith(
          isLoading: false,
          error: null,
          productDetail: productDetail,
          clearProductDetail: false,
        );


      } else {
        // Handles cases where success is false or data is missing
        state = state.copyWith(
          isLoading: false,
          error: "Product detail not found or invalid response format",
          clearProductDetail: true,
        );

      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        error: "Failed to load product details: ${e.toString()}",
        clearProductDetail: true,
      );
    }
  }

  Future<BPProductData?> fetchProductByCode(String code) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await ApiClient().get(
          endpoint: "api/common/get-product-details?product_code=$code");


      if (response["status"] == 1 && response["data"] != null) {
        final data = response["data"];
        if (data["success"] == true && data["product"] != null) {
          final productModel = BPProductModel.fromJson(data);
          state = state.copyWith(isSaving: false);
          return productModel.product;
        } else {
          state = state.copyWith(isSaving: false);
          return null;
        }
      } else {
        state = state.copyWith(isSaving: false);
        return null;
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isSaving: false,
        error: "Failed to load product by code: $e",
      );
      return null;
    }
  }

  void filterBuyers(String filterKey, String query) {
    if (query.isEmpty) {
      state = state.copyWith(products: state.allProducts);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredList = state.allProducts.where((catalogue) {
      switch (filterKey) {
        case 'Buyer Code':
          return (catalogue.bpCode ?? '').toLowerCase().contains(
              lowerQuery);
        case 'Buyer Name':
          return (catalogue.productName ?? '').toLowerCase().contains(
              lowerQuery);
        case 'Email':
          return (catalogue.productCode ?? '').toLowerCase().contains(
              lowerQuery);
        default:
          return false;
      }
    }).toList();

    state = state.copyWith(products: filteredList);
  }

  void sortBuyers(String sortKey, {bool ascending = true}) {
    final currentList = List<Product>.from(state.products);

    int compare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    }

    currentList.sort((a, b) {
      int result = 0;

      switch (sortKey) {
        case 'Bp Code':
          result = compare(a.bpCode, b.bpCode);
          break;
        case 'Product Name':
          result = compare(a.productName, b.productName);
          break;
        case 'productCode':
          result = compare(a.productCode, b.productCode);
          break;
      }

      return ascending ? result : -result;
    });

    state = state.copyWith(products: currentList);
  }

  void resetCataloguesPartners() {
    state = state.copyWith(
      products: state.allProducts,
      error: null,
      isLoaded: true,
    );
  }

  /// Bulk upload products via .zip file
  Future<bool> bulkUploadProducts(PlatformFile file) async {
    state = state.copyWith(isBulkUploading: true, error: null);
    try {
      final response = await ApiClient().requestWithFiles(
        method: 'POST',
        endpoint: 'api/common/products/bulk-upload',
        files: {'zip_file': file},
      );
     print(response);
      if (response["status"] == 1 && response["data"] != null) {
        final data = response["data"];
        final message = data["message"] ?? "Bulk upload successful";
        Toaster.showSuccess(message.toString());
        await fetchProducts();
        state = state.copyWith(isBulkUploading: false);
        return true;
      } else {
        final errorMsg = _extractErrorMessage(response["message"]);
        Toaster.showError(errorMsg);
        state = state.copyWith(isBulkUploading: false, error: errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = e.toString();
      Toaster.showError(errorMsg);
      state = state.copyWith(isBulkUploading: false, error: errorMsg);
      return false;
    }
  }
}

final productListProvider =
StateNotifierProvider<ProductListNotifier, ProductListState>(
      (ref) => ProductListNotifier(),
);