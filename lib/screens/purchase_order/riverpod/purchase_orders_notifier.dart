// riverpod/purchase_orders_notifier.dart
import 'dart:convert';
import 'dart:io';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/purchase_order/model/purchase_orders_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';


import '../../../services/widget/custom_msg.dart';

class PurchaseOrderListState {
  final bool isLoading;
  final bool isLoaded;
  final bool assignLoad;
  final bool isDetailsView;
  final String? error;
  final String? urls;
  final String? sortOrder;
  final List<PurchaseOrder> purchaseOrders;
  final List<PurchaseOrder> allPurchaseOrders;
  final List<Map<String, dynamic>> importedExcelItems;

  final bool isSavingPO;
  final bool isCreatingItem;
  final PurchaseOrder? purchaseOrderDetail;
  final PurchaseOrder? currentPurchaseOrderDetail;
  final String? craftsmanAcceptId;
  final String? craftsmanRejectId;


  // Counts for status cards
  final int createdOrders;
  final int allocatedOrders;
  final int forApprovalOrders;
  final int completedOrders;
  final int inProcessOrders;
  final int rejectedOrders;
  final int totalCount;
  final int count;
  final bool isProcessingItems;
  final String? nextUrl;
  final String? previousUrl;

  const PurchaseOrderListState({
    this.isLoading = false,
    this.assignLoad = false,
    this.isLoaded = false,
    this.isDetailsView = false,
    this.error,
    this.urls,
    this.sortOrder,
    this.purchaseOrders = const [],
    this.allPurchaseOrders = const [],
    this.importedExcelItems = const [],
    this.isSavingPO = false,
    this.isCreatingItem = false,
    this.purchaseOrderDetail,
    this.currentPurchaseOrderDetail,
    this.createdOrders = 0,
    this.allocatedOrders = 0,
    this.inProcessOrders = 0,
    this.forApprovalOrders = 0,
    this.completedOrders = 0,
    this.rejectedOrders = 0,
    this.totalCount = 0,
    this.craftsmanAcceptId,
    this.craftsmanRejectId,
    this.isProcessingItems = false,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
  });

  PurchaseOrderListState copyWith({
    bool? isLoading,
    bool? assignLoad,
    bool? isLoaded,
    bool? isDetailsView,
    String? error,
    String? urls,
    String? sortOrder,
    List<PurchaseOrder>? purchaseOrders,
    List<PurchaseOrder>? allPurchaseOrders,
    List<Map<String, dynamic>>? importedExcelItems,
    bool? isSavingPO,
    bool? isCreatingItem,
    PurchaseOrder? purchaseOrderDetail,
    PurchaseOrder? currentPurchaseOrderDetail,
    int? createdOrders,
    int? allocatedOrders,
    int? inProcessOrders,
    int? forApprovalOrders,
    int? completedOrders,
    int? rejectedOrders,
    int? totalCount,
    bool? isProcessingItems,
    String? craftsmanAcceptId,
    String? craftsmanRejectId,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
  }) {
    return PurchaseOrderListState(
      isLoading: isLoading ?? this.isLoading,
      assignLoad: assignLoad ?? this.assignLoad,
      isLoaded: isLoaded ?? this.isLoaded,
      isDetailsView: isDetailsView ?? this.isDetailsView,
      error: error,
      urls: urls ?? this.urls,
      sortOrder: sortOrder ?? this.sortOrder,
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      importedExcelItems: importedExcelItems ?? this.importedExcelItems,
      allPurchaseOrders: allPurchaseOrders ?? this.allPurchaseOrders,
      isSavingPO: isSavingPO ?? this.isSavingPO,
      isCreatingItem: isCreatingItem ?? this.isCreatingItem,
      purchaseOrderDetail: purchaseOrderDetail ?? this.purchaseOrderDetail,
      currentPurchaseOrderDetail: currentPurchaseOrderDetail ?? this.currentPurchaseOrderDetail,
      createdOrders: createdOrders ?? this.createdOrders,
      allocatedOrders: allocatedOrders ?? this.allocatedOrders,
      inProcessOrders: inProcessOrders ?? this.inProcessOrders,
      forApprovalOrders: forApprovalOrders ?? this.forApprovalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      rejectedOrders: rejectedOrders ?? this.rejectedOrders,
      totalCount: totalCount ?? this.totalCount,
      isProcessingItems: isProcessingItems ?? this.isProcessingItems,
      craftsmanAcceptId: craftsmanAcceptId ?? this.craftsmanAcceptId,
      craftsmanRejectId: craftsmanRejectId ?? this.craftsmanRejectId,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
    );
  }
}

const _sentinel = Object();

class PurchaseOrderListNotifier extends StateNotifier<PurchaseOrderListState> {
  final Ref ref;
  PurchaseOrderListNotifier(this.ref) : super(PurchaseOrderListState());

  void clearProcessedItems() {
    final remaining = state.importedExcelItems.where((item) => item['isSelected'] == false).toList();
    state = state.copyWith(importedExcelItems: remaining);
  }

  /// Fetch purchase orders
  Future<void> fetchPurchaseOrders({String? customUrl}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      urls: customUrl ?? state.urls,
    );

    String endpoint = customUrl ?? 'api/common/purchase-orders';

    // 1. Log the initiation of the request


    try {
      final response = await ApiClient().get(endpoint: endpoint);
      if (response != null && response["status"] == 1) {
        // response["data"] is the full API response object (success, counts, data)
        final actualResponse = response["data"];
        final rawPaginationData = actualResponse["data"];
        final counts = actualResponse["counts"];

        if (rawPaginationData == null) {
          throw Exception("Pagination data is missing");
        }

        final List<dynamic> listData = rawPaginationData["data"] ?? [];
        final orders = listData.map((json) => PurchaseOrder.fromJson(json)).toList();

        // 2. Extract counts if available
        final int createdOrders     = counts?['created'] ?? 0;
        final int allocatedOrders   = counts?['allocated'] ?? 0;
        final int inProcessOrders   = counts?['in_process'] ?? 0;
        final int forApprovalOrders = counts?['for_approval'] ?? 0;
        final int completedOrders   = counts?['completed'] ?? 0;
        final int rejectedOrders    = counts?['rejected'] ?? 0;
        final int allOrders         = counts?['all'] ?? 0;

        // Log success with helpful metadata


        state = state.copyWith(
          isLoading: false,
          purchaseOrders: orders,
          allPurchaseOrders: orders,
          createdOrders: createdOrders,
          allocatedOrders: allocatedOrders,
          inProcessOrders: inProcessOrders,
          forApprovalOrders: forApprovalOrders,
          completedOrders: completedOrders,
          rejectedOrders: rejectedOrders,
          totalCount: allOrders,
          count: rawPaginationData["total"] ?? 0,
          nextUrl: rawPaginationData["next_page_url"],
          previousUrl: rawPaginationData["prev_page_url"],
        );
      } else {
        // 3. Log logic errors (like 401 or custom API errors)
        String errorMsg = response?["message"]?.toString() ?? "Failed to fetch purchase orders";


        state = state.copyWith(
          isLoading: false,
          error: errorMsg,
        );
      }
    } catch (e, stacktrace) {
      // 4. Log severe exceptions with stacktrace for debugging


      state = state.copyWith(
        isLoading: false,
        error: "Connection Error: ${e.toString()}",
      );
    }
  }

  Future<Map<String, dynamic>?> createPurchaseOrder({
    required BuildContext context,
    required Map<String, dynamic> payload,
    String? id,
    Map<String, dynamic>? files,
  }) async {
    state = state.copyWith(isSavingPO: true, error: null);

    try {
      final bool isUpdate = id != null && id.isNotEmpty && id != "null";
      final String method = isUpdate ? "POST" : "POST"; // Based on usual pattern in this codebase for multipart
      final String endpoint = isUpdate 
          ? "api/common/purchase-orders/$id" 
          : "api/common/purchase-orders";

      final response = await ApiClient().requestWithFiles(
        method: method,
        endpoint: endpoint,
        fields: payload,
        files: files,
      );

      if (response != null && response["status"] == 1) {
        clearProcessedItems();
        
        await ref.read(dashboardProvider.notifier).fetchDashBoard();
        await fetchPurchaseOrders();
        
        state = state.copyWith(isSavingPO: false);
        return response; 
      } else {
        final errorMsg = response?["message"]?.toString() ?? 'Invalid response';
        state = state.copyWith(isSavingPO: false, error: errorMsg);
        return response;
      }
    } catch (e) {
      state = state.copyWith(isSavingPO: false, error: e.toString());
      return null;
    }
  }


  Future<bool> assignOrder(BuildContext context, Map<String, dynamic> payload) async {
    state = state.copyWith(assignLoad: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/bulk-allocate",
        body: payload,
      );
      print("allocated Order response: $response");

      bool isSuccess = false;
      String displayMessage = 'Failed to allocate';

      if (response != null && response['status'] == 1) {
        final messageData = response['data'];
        
        if (messageData != null && messageData['success'] == true) {
          isSuccess = true;
          displayMessage = messageData['message']?.toString() ?? 'Purchase Orders allocated successfully!';
        } else {
          displayMessage = messageData?['message']?.toString() ?? displayMessage;
        }
      } else if (response != null) {
        // Fallback for older/different error response formats
        final messageData = response['message'];
        
        if (messageData is Map) {
          isSuccess = messageData['success'] == true;
          displayMessage = messageData['message']?.toString() ?? displayMessage;

          if (messageData['errors'] != null && messageData['errors'] is Map) {
            final errors = messageData['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstErrorKey = errors.keys.first;
              final firstErrorList = errors[firstErrorKey];
              if (firstErrorList is List && firstErrorList.isNotEmpty) {
                displayMessage = "$displayMessage: ${firstErrorList.first}";
              }
            }
          }
        } else if (response['success'] != null) {
          isSuccess = response['success'] == true;
          displayMessage = response['message']?.toString() ?? displayMessage;
        }
      }

      if (isSuccess) {
        Toaster.showSuccess(displayMessage);
        Get.back();
        await fetchPurchaseOrders(
            customUrl: "api/common/purchase-orders?tab=created");
        state = state.copyWith(assignLoad: false);
        return true;
      } else {
        Toaster.showError(displayMessage);
        state = state.copyWith(assignLoad: false, error: displayMessage);
        return false;
      }
    } catch (e, st) {

      state = state.copyWith(assignLoad: false, error: e.toString());
      Toaster.showError("Error: ${e.toString()}");
      return false;
    }
  }

  Future<bool> approveOrder(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    state = state.copyWith(assignLoad: true, error: null);

    try {
      final response = await ApiClient()
          .post(endpoint: "api/common/purchase-orders/bulk-approve", body: payload);

      bool isSuccess = false;
      String displayMessage = "Failed to approve orders.";

      if (response != null) {
        if (response['status'] == 1 && response['data'] != null) {
          final data = response['data'];
          if (data['success'] == true) {
            isSuccess = true;
            displayMessage = data['message']?.toString() ?? "Orders Approved successfully!";
          } else {
            displayMessage = data['message']?.toString() ?? displayMessage;
            if (data['errors'] != null && data['errors'] is Map) {
              final Map errors = data['errors'];
              final String firstErrorKey = errors.keys.first;
              final firstErrorList = errors[firstErrorKey];
              if (firstErrorList is List && firstErrorList.isNotEmpty) {
                displayMessage = "$displayMessage: ${firstErrorList.first}";
              }
            }
          }
        } else if (response['success'] != null) {
          isSuccess = response['success'] == true;
          displayMessage = response['message']?.toString() ?? displayMessage;
        }
      }

      if (isSuccess) {
        Toaster.showSuccess(displayMessage);
        Get.back();
        await fetchPurchaseOrders(
            customUrl: state.urls);
        state = state.copyWith(assignLoad: false);
        return true;
      } else {
        Toaster.showError(displayMessage);
        state = state.copyWith(assignLoad: false, error: displayMessage);
        return false;
      }
    } catch (e, st) {

      state = state.copyWith(assignLoad: false, error: e.toString());
      Toaster.showError("Error: ${e.toString()}");
      return false;
    }
  }

  Future<void> purchaseOrderDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/purchase-orders/$id");
      final outerData = response["data"];

      if (outerData != null && outerData["data"] != null) {
        final productDetail = PurchaseOrder.fromJson(outerData['data']);
        state = state.copyWith(
          isLoading: false,
          error: null,
          purchaseOrderDetail: productDetail,
        );

      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Purchase order details not found",
          purchaseOrderDetail: null,
        );
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        error: "Failed to load purchase details: ${e.toString()}",
      );
    }
  }
  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      print('next -> $relativeUrl');
      state = state.copyWith(purchaseOrders: []);
      fetchPurchaseOrders(customUrl: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      state = state.copyWith(purchaseOrders: []);
      fetchPurchaseOrders(customUrl: relativeUrl);
    }
  }
  void filterBuyers(String filterKey, String query) {
    if (query.isEmpty) {
      state = state.copyWith(purchaseOrders: state.allPurchaseOrders);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredList = state.allPurchaseOrders.where((catalogue) {
      switch (filterKey) {
        case 'Buyer Code':
          return (catalogue.bpCode ?? '').toLowerCase().contains(lowerQuery);
        case 'PO Number':
          return (catalogue.orderNumber ?? '').toLowerCase().contains(lowerQuery);
        case 'Date':
          return (catalogue.orderDate ?? '').toLowerCase().contains(lowerQuery);
        case 'Due Date':
          return (catalogue.dueDate ?? '').toLowerCase().contains(lowerQuery);
        default:
          return false;
      }
    }).toList();

    state = state.copyWith(purchaseOrders: filteredList);
  }

  void sortBuyers(String sortKey, {bool ascending = true}) {
    final currentList = List<PurchaseOrder>.from(state.purchaseOrders);

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
        case 'PO Number':
          result = compare(a.orderNumber, b.orderNumber);
          break;
        case 'Date':
          result = compare(a.orderDate, b.orderDate);
          break;
        case 'Due Date':
          result = compare(a.dueDate, b.dueDate);
          break;
      }

      return ascending ? result : -result;
    });

    state = state.copyWith(purchaseOrders: currentList);
  }

  void resetCataloguesPartners() {
    state = state.copyWith(
      purchaseOrders: state.allPurchaseOrders,
      error: null,
      isLoaded: true,
    );
  }

  Future<void> bulkAcceptPurchaseOrders(List<int> ids) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/bulk-accept",
        body: {"purchase_order_ids": ids},
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders accepted successfully");
        fetchPurchaseOrders(customUrl: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to accept orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> bulkRejectPurchaseOrders(List<int> ids, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/bulk-reject",
        body: {"purchase_order_ids": ids,},
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders rejected successfully");
        fetchPurchaseOrders(customUrl: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to reject orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> processPurchaseOrderItems({
    required String orderId,
    required List<int> acceptIndices,
    required List<int> rejectIndices,
  }) async {
    state = state.copyWith(isProcessingItems: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/$orderId/process-items",
        body: {
          "action": "process",
          "accepted_items": acceptIndices,
          "rejected_items": rejectIndices,
        },
      );
     print(response);
      if (response['data'] != null && response["status"] == 1) {
        // Handle nested message properly
        final message = response["data"]?["message"] ?? "Items processed successfully";
        Toaster.showSuccess(message);
        await purchaseOrderDetail(orderId);
        await fetchPurchaseOrders(customUrl: state.urls);
      } else {
        Toaster.showError(response?["message"]?['message'] ?? "Failed to process items");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isProcessingItems: false);
    }
  }

  Future<void> bulkCompletePurchaseOrders(List<int> ids) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/bulk-complete",
        body: {"purchase_order_ids": ids},
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders completed successfully");
        fetchPurchaseOrders(customUrl: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to complete orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> reallocatePurchaseOrders(String id) async {
    state = state.copyWith(assignLoad: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/purchase-orders/$id/reallocate",
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders reallocated successfully");
        fetchPurchaseOrders(customUrl: state.urls);
        state = state.copyWith(assignLoad: false);
        return true;
      } else {
        final msg = response?["message"] ?? "Failed to reallocate orders";
        Toaster.showError(msg);
        state = state.copyWith(assignLoad: false, error: msg.toString());
        return false;
      }
    } catch (e) {
      Toaster.showError("Error: $e");
      state = state.copyWith(assignLoad: false, error: e.toString());
      return false;
    }
  }

  void resetCurrentOrder() {
    state = state.copyWith(currentPurchaseOrderDetail: null);
  }
}

final purchaseOrderListProvider =
StateNotifierProvider<PurchaseOrderListNotifier, PurchaseOrderListState>(
      (ref) => PurchaseOrderListNotifier(ref),
);