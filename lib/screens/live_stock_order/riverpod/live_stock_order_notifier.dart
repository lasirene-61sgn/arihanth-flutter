import 'package:arianth/screens/live_stock_order/model/stock_order_form_model.dart';
import 'package:arianth/screens/live_stock_order/model/stock_order_detail_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class LiveStockOrderState {
  final bool isLoading;
  final String? error;
  final List<StockOrderDetailModel> liveStockOrders;
  final int count;
  final String? nextUrl;
  final String? urls;
  final String? previousUrl;
  final List<Map<String, dynamic>> scannedItems;
  final bool isSavingOrder;
  final bool isAllocating;
  final bool isAccepting;
  final bool isRejecting;
  final bool isCompleting;
  final StockOrderDetailModel? stockOrderDetail;

  // Status counts
  final int newOrders;
  final int allocatedOrders;
  final int inProcessOrders;
  final int forApprovalOrders;
  final int completedOrders;
  final int rejectedOrders;
  final int allOrders;

  LiveStockOrderState({
    this.isLoading = false,
    this.error,
    this.liveStockOrders = const [],
    this.count = 0,
    this.nextUrl,
    this.urls,
    this.previousUrl,
    this.scannedItems = const [],
    this.isSavingOrder = false,
    this.isAllocating = false,
    this.isAccepting = false,
    this.isRejecting = false,
    this.isCompleting = false,
    this.stockOrderDetail,
    this.newOrders = 0,
    this.allocatedOrders = 0,
    this.inProcessOrders = 0,
    this.forApprovalOrders = 0,
    this.completedOrders = 0,
    this.rejectedOrders = 0,
    this.allOrders = 0,
  });

  LiveStockOrderState copyWith({
    bool? isLoading,
    String? error,
    List<StockOrderDetailModel>? liveStockOrders,
    int? count,
    String? nextUrl,
    String? urls,
    String? previousUrl,
    List<Map<String, dynamic>>? scannedItems,
    bool? isSavingOrder,
    bool? isAllocating,
    bool? isAccepting,
    bool? isRejecting,
    bool? isCompleting,
    StockOrderDetailModel? stockOrderDetail,
    bool clearStockOrderDetail = false,
    int? newOrders,
    int? allocatedOrders,
    int? inProcessOrders,
    int? forApprovalOrders,
    int? completedOrders,
    int? rejectedOrders,
    int? allOrders,
  }) {
    return LiveStockOrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      liveStockOrders: liveStockOrders ?? this.liveStockOrders,
      count: count ?? this.count,
      nextUrl: nextUrl ?? this.nextUrl,
      urls: urls ?? this.urls,
      previousUrl: previousUrl ?? this.previousUrl,
      scannedItems: scannedItems ?? this.scannedItems,
      isSavingOrder: isSavingOrder ?? this.isSavingOrder,
      isAllocating: isAllocating ?? this.isAllocating,
      isAccepting: isAccepting ?? this.isAccepting,
      isRejecting: isRejecting ?? this.isRejecting,
      isCompleting: isCompleting ?? this.isCompleting,
      stockOrderDetail: clearStockOrderDetail ? null : (stockOrderDetail ?? this.stockOrderDetail),
      newOrders: newOrders ?? this.newOrders,
      allocatedOrders: allocatedOrders ?? this.allocatedOrders,
      inProcessOrders: inProcessOrders ?? this.inProcessOrders,
      forApprovalOrders: forApprovalOrders ?? this.forApprovalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      rejectedOrders: rejectedOrders ?? this.rejectedOrders,
      allOrders: allOrders ?? this.allOrders,
    );
  }
}

class LiveStockOrderNotifier extends StateNotifier<LiveStockOrderState> {
  LiveStockOrderNotifier() : super(LiveStockOrderState());

  Future<void> fetchLiveStockOrders({String? customUrl, bool isNext = false}) async {
    final String endpoint = customUrl ?? state.urls ?? 'api/common/stock-orders?tab=all-orders';
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      urls: endpoint,
    );

    try {
      final response = await ApiClient().get(endpoint: endpoint);
      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        // Handle nested response format similar to WorkOrder
        final bool isSuccess = actualResponse["success"] == true;
        final rawPaginationData = isSuccess ? actualResponse["data"] : actualResponse;
        final counts = isSuccess ? actualResponse["counts"] : null;

        final List<dynamic> listData = rawPaginationData["data"] ?? [];
        final orders = listData.map((json) => StockOrderDetailModel.fromJson(json)).toList();

        state = state.copyWith(
          isLoading: false,
          liveStockOrders: isNext ? [...state.liveStockOrders, ...orders] : orders,
          count: rawPaginationData["total"] ?? orders.length,
          nextUrl: rawPaginationData["next_page_url"],
          previousUrl: rawPaginationData["prev_page_url"],
          newOrders: counts?['new-orders'] ?? 0,
          allocatedOrders: counts?['allocated-orders'] ?? 0,
          inProcessOrders: counts?['in-process-orders'] ?? 0,
          forApprovalOrders: counts?['for-approval-orders'] ?? 0,
          completedOrders: counts?['completed-orders'] ?? 0,
          rejectedOrders: counts?['rejected-orders'] ?? 0,
          allOrders: counts?['all-orders'] ?? 0,
        );
      } else {
        String errorMsg = response?["message"]?.toString() ?? "Failed to fetch stock orders";
        state = state.copyWith(
          isLoading: false,
          error: errorMsg,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Connection Error: ${e.toString()}",
      );
    }
  }

  Future<void> goToNextPage() async {
    if (state.nextUrl != null && !state.isLoading) {
      await fetchLiveStockOrders(customUrl: state.nextUrl, isNext: true);
    }
  }

  Future<void> goToPreviousPage() async {
    if (state.previousUrl != null && !state.isLoading) {
      await fetchLiveStockOrders(customUrl: state.previousUrl, isNext: false);
    }
  }

  void updateScannedItems(List<Map<String, dynamic>> items) {
    state = state.copyWith(scannedItems: items);
  }

  void clearScannedItems() {
    state = state.copyWith(scannedItems: []);
  }

  Future<void> fetchLiveStockOrderDetail(String id) async {
    final bool isSameId = state.stockOrderDetail?.id.toString() == id;
    state = state.copyWith(
      isLoading: true, 
      error: null, 
      clearStockOrderDetail: !isSameId
    );
    try {
      final response = await ApiClient().get(endpoint: 'api/common/stock-orders/$id');
      if (response != null && (response["status"] == 1 || response["data"]?["success"] == true)) {
        final data = response["data"]["data"];
        if (data != null) {
          state = state.copyWith(
            isLoading: false,
            stockOrderDetail: StockOrderDetailModel.fromJson(data),
          );
        } else {
          state = state.copyWith(isLoading: false, error: "Stock order data not found.");
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response?["message"]?.toString() ?? "Failed to fetch stock order details",
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Error: ${e.toString()}");
    }
  }

  Future<bool> fetchItemByCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: 'api/common/stock-orders/lookup/$code');
      if (response != null && response["status"] == 1) {
        final responseData = response["data"];
        if (responseData != null && responseData["success"] == true && responseData["product"] != null) {
          final formModel = StockOrderFormModel.fromJson(responseData);
          final data = formModel.product!;

          // Check if item is already added to prevent duplicates
          final existingIdx = state.scannedItems.indexWhere((item) {
             final stockData = item['stockData'];
             if (stockData is FormProduct) {
               return stockData.id == data.id;
             }
             return false;
          });
          if (existingIdx != -1) {
            state = state.copyWith(isLoading: false, error: "Item already added");
            return false;
          }

          final Map<String, dynamic> newItem = {
            'stockData': data,
            'productId': data.id?.toString(),
            'designCode': data.designCode ?? '',
            'sizeCtrl': data.size == 'N/A' ? '' : (data.size ?? ''),
            'notesCtrl': '',
            'serverImage': data.image,
            'selectedFiles': [],
            'subItems': [
              {
                'gramsCtrl': data.weightFrom ?? '',
                'qtyCtrl': '1',
                'totalWeightCtrl': ((double.tryParse(data.weightFrom ?? '0') ?? 0) * 1).toStringAsFixed(2),
              }
            ],
            'totalWeightCtrl': ((double.tryParse(data.weightFrom ?? '0') ?? 0) * 1).toStringAsFixed(2),
          };

          state = state.copyWith(
            isLoading: false,
            scannedItems: [...state.scannedItems, newItem],
          );
          return true;
        } else {
           state = state.copyWith(isLoading: false, error: "Item not found");
           return false;
        }
      }
      state = state.copyWith(isLoading: false, error: response?["message"]?.toString() ?? "Item not found");
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> createStockOrder({
    required BuildContext context,
    required Map<String, dynamic> payload,
    String? id,
    Map<String, dynamic>? files,
  }) async {
    state = state.copyWith(isSavingOrder: true, error: null);
    try {
      final bool isUpdate = id != null && id.isNotEmpty && id != "null";
      final String method = isUpdate ? "POST" : "POST";
      final String endpoint = isUpdate ? "api/common/stock-orders/$id" : "api/common/stock-orders";

      final response = await ApiClient().requestWithFiles(
        method: method,
        endpoint: endpoint,
        fields: payload,
        files: files,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(isUpdate ? "Order updated successfully" : "Order created successfully");
        clearScannedItems();
        await fetchLiveStockOrders();
        if (context.mounted) Navigator.pop(context);
      } else {
        final errorMsg = response?["message"]?.toString() ?? 'Failed to save order';
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isSavingOrder: false);
    }
  }

  Future<void> allocateStockOrder(String id, Map<String, dynamic> payload) async {
    state = state.copyWith(isAllocating: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/allocate",
        body: payload,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order allocated successfully");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to allocate stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isAllocating: false);
    }
  }

  Future<void> bulkAllocateStockOrders(Map<String, dynamic> payload) async {
    state = state.copyWith(isAllocating: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/bulk-allocate",
        body: payload,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Orders allocated successfully");
        await fetchLiveStockOrders();
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to allocate stock orders";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isAllocating: false);
    }
  }

  Future<void> bulkAcceptStockOrders(List<int> ids) async {
    state = state.copyWith(isAccepting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/bulk-accept",
        body: {"order_ids": ids},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Orders accepted successfully");
        await fetchLiveStockOrders();
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to accept stock orders";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isAccepting: false);
    }
  }

  Future<void> bulkRejectStockOrders(List<int> ids, String reason) async {
    state = state.copyWith(isRejecting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/bulk-reject",
        body: {
          "order_ids": ids,
          "rejection_reason": reason,
        },
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Orders rejected successfully");
        await fetchLiveStockOrders();
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to reject stock orders";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isRejecting: false);
    }
  }

  Future<void> bulkCompleteStockOrders(List<int> ids) async {
    state = state.copyWith(isCompleting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/bulk-complete",
        body: {"order_ids": ids},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Orders marked as completed");
        await fetchLiveStockOrders();
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to complete stock orders";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isCompleting: false);
    }
  }

  Future<void> acceptStockOrder(String id, String itemId) async {
    state = state.copyWith(isAccepting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/items/$itemId/accept",
        body: {},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order accepted successfully");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to accept stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isAccepting: false);
    }
  }

  Future<void> rejectStockOrder(String id, String itemId, String reason) async {
    state = state.copyWith(isRejecting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/items/$itemId/reject",
        body: {"rejection_reason": reason},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order rejected successfully");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to reject stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isRejecting: false);
    }
  }

  Future<void> completeStockOrder(String id) async {
    state = state.copyWith(isCompleting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/complete",
        body: {},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order marked as completed");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to complete stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isCompleting: false);
    }
  }

  Future<void> finishStockOrder(String id, String itemId) async {
    state = state.copyWith(isCompleting: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/items/$itemId/finish",
        body: {},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order marked as completed");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to finish stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isCompleting: false);
    }
  }

  Future<void> reallocateStockOrder(String id, Map<String, dynamic> payload) async {
    state = state.copyWith(isAllocating: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/stock-orders/$id/reallocate",
        body: payload,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Order reallocated successfully");
        await fetchLiveStockOrderDetail(id);
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Failed to reallocate stock order";
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isAllocating: false);
    }
  }
}

final liveStockOrderNotifierProvider =
    StateNotifierProvider<LiveStockOrderNotifier, LiveStockOrderState>(
  (ref) => LiveStockOrderNotifier(),
);