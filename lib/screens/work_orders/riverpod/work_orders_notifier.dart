// riverpod/purchase_orders_notifier.dart
import 'dart:convert';
import 'dart:io';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/work_orders/model/work_orders_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';

import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';

class WorkOrderListState {
  final bool isLoading;
  final bool isLoaded;
  final bool assignLoad;
  final String? craftsmanAcceptId;
  final String? craftsmanRejectId;
  final String? error;
  final String? urls;
  final String? sortOrder;
  final List<WorkOrder> workOrders;
  final List<WorkOrder> allWorkOrders;

  final bool isSaving;
  final WorkOrder? workOrderDetail;

  // ----- NEW COUNTS -------------------------------------------------
  final int newOrders;
  final int allocatedOrders;
  final int inProcessOrders;
  final int forApprovalOrders;
  final int completedOrders;
  final int rejectedOrders;
  final int overdueOrders;
  final int totalCount;
  // -----------------------------------------------------------------
  final int count;
  final String? nextUrl;
  final String? previousUrl;

  const WorkOrderListState({
    this.isLoading = false,
    this.assignLoad = false,
    this.craftsmanAcceptId,
    this.craftsmanRejectId,
    this.isLoaded = false,
    this.error,
    this.urls,
    this.sortOrder,
    this.workOrders = const [],
    this.allWorkOrders = const [],
    this.isSaving = false,
    this.workOrderDetail,
    // defaults
    this.newOrders = 0,
    this.allocatedOrders = 0,
    this.inProcessOrders = 0,
    this.forApprovalOrders = 0,
    this.completedOrders = 0,
    this.rejectedOrders = 0,
    this.totalCount = 0,
    this.overdueOrders = 0,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
  });

  WorkOrderListState copyWith({
    bool? isLoading,
    bool? assignLoad,
    String? craftsmanAcceptId,
    String? craftsmanRejectId,
    bool? isLoaded,
    String? error,
    String? urls,
    String? sortOrder,
    List<WorkOrder>? workOrders,
    List<WorkOrder>? allWorkOrders,
    bool? isSaving,
    WorkOrder? workOrderDetail,
    int? newOrders,
    int? allocatedOrders,
    int? inProcessOrders,
    int? forApprovalOrders,
    int? completedOrders,
    int? rejectedOrders,
    int? totalCount,
    int? overdueOrders,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
  }) {
    return WorkOrderListState(
      isLoading: isLoading ?? this.isLoading,
      assignLoad: assignLoad ?? this.assignLoad,
      craftsmanAcceptId: craftsmanAcceptId ?? this.craftsmanAcceptId,
      craftsmanRejectId: craftsmanRejectId ?? this.craftsmanRejectId,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error, // Error is typically ephemeral and can be cleared
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      urls: urls ?? this.urls,
      sortOrder: sortOrder ?? this.sortOrder,
      workOrders: workOrders ?? this.workOrders,
      allWorkOrders: allWorkOrders ?? this.allWorkOrders,
      isSaving: isSaving ?? this.isSaving,
      workOrderDetail: workOrderDetail ?? this.workOrderDetail,
      newOrders: newOrders ?? this.newOrders,
      allocatedOrders: allocatedOrders ?? this.allocatedOrders,
      inProcessOrders: inProcessOrders ?? this.inProcessOrders,
      forApprovalOrders: forApprovalOrders ?? this.forApprovalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      rejectedOrders: rejectedOrders ?? this.rejectedOrders,
      overdueOrders: overdueOrders ?? this.overdueOrders,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

const _sentinel = Object();

class WorkOrderListNotifier extends StateNotifier<WorkOrderListState> {
  final Ref ref;
  WorkOrderListNotifier(this.ref) : super( WorkOrderListState());

  /// Fetch work orders
  /// Fetch work orders
  Future<void> fetchWorkOrders({String? urls,}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      urls: urls ?? state.urls,
    );

    String endpoint = urls ?? 'api/common/work-orders?tab=all-orders';

    try {
      final response = await ApiClient().get(endpoint: endpoint);
      // 1. Unwrap the outer response layer
      // Based on your log: {status: 1, data: {success: true, counts: {...}, data: {...}}}
      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"]; // This contains success, counts, and the data object

        if (actualResponse != null && actualResponse["success"] == true) {
          final rawData = actualResponse["data"]; // This is the pagination object (current_page, data, etc.)
          final counts = actualResponse["counts"]; // The counts object

          final List<dynamic> orderList = rawData["data"] ?? [];
          final workOrders = orderList.map((item) => WorkOrder.fromJson(item)).toList();

          // 2. Map counts using the precise keys from your log
          final int newOrders         = counts['new'] ?? 0;
          final int allocatedOrders   = counts['allocated'] ?? 0;
          final int inProcessOrders   = counts['in_process'] ?? 0;
          final int forApprovalOrders = counts['for_approval'] ?? 0;
          final int completedOrders   = counts['completed'] ?? 0;
          final int rejectedOrders    = counts['rejected'] ?? 0;
          final int overdueOrders     = counts['overdue'] ?? 0;
          final int totalCount        = counts['all'] ?? 0;

          // 3. Map Pagination from the nested rawData object
          final String? nextUrl       = rawData["next_page_url"];
          final String? previousUrl   = rawData["prev_page_url"];
          final int apiTotalCount     = rawData["total"] as int? ?? 0;
          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            workOrders: workOrders,
            allWorkOrders: workOrders,
            newOrders: newOrders,
            allocatedOrders: allocatedOrders,
            inProcessOrders: inProcessOrders,
            forApprovalOrders: forApprovalOrders,
            completedOrders: completedOrders,
            rejectedOrders: rejectedOrders,
            overdueOrders: overdueOrders,
            totalCount: totalCount,
            count: apiTotalCount,
            nextUrl: nextUrl,
            previousUrl: previousUrl,
          );
        } else {
          state = state.copyWith(
              isLoading: false,
              error: actualResponse?["message"]?.toString() ?? "API reported failure"
          );
        }
      } else {
        final errorMsg = response?["message"]?.toString() ?? "Server connection failed";
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e, st) {
      debugPrint("Fetch error: $e\n$st");
      state = state.copyWith(
          isLoading: false,
          error: "Connection Error: ${e.toString()}"
      );
    }
  }
  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      print("final next ->$relativeUrl");
      state = state.copyWith(workOrders: []);
      fetchWorkOrders(urls: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      state = state.copyWith(workOrders: []);
      fetchWorkOrders(urls: relativeUrl);
    }
  }
  /// Save new Work Order
  Future<void> saveWorkOrder(
      BuildContext context,
      Map<String, dynamic> payload,
      Map<String, dynamic>? files,
  {String? id,
    String? url
  }
      ) async {
    state = state.copyWith(isSaving: true, error: null);
   String? role;
    role = SharedPreferencesHelper().getString("role") ?? '';
    try {

      final response = await ApiClient().requestWithFiles(
        endpoint: url ?? "api/common/work-orders",
        method: "POST",
        files: files,
        fields: payload
      );
      print(response);

      if (response["data"] != null && response["status"] == 1) {
        await fetchWorkOrders();
        await ref.read(dashboardProvider.notifier).fetchDashBoard();
        // final newOrder = WorkOrder.fromJson(response["data"]);

        state = state.copyWith(
          isSaving: false,
          // workOrders: [...state.workOrders, newOrder],
        );


        String successMessage = "Work Order Created";
        if (response['data'] != null && response['data']['message'] != null) {
          successMessage = response['data']['message'];
        }
        Toaster.showSuccess(successMessage);
        if (id == null) {
           final orderNo = response["data"]?["data"]?["order_no"]?.toString() ?? 
                         response["data"]?["data"]?["id"]?.toString() ?? "";
           Get.offNamed(AppRoutes.orderSuccess, arguments: {
             'orderNo': orderNo,
             'orderType': 'Work Order',
             'onBack': () => Get.back(),
           });
        } else {
           Get.back();
        }
      } else {
        String errorMessage = "Failed to save Work Order.";
      
        if (response['message'] != null) {
          if (response['message'] is Map && response['message']['errors'] != null) {
            // Extract specific validation errors
            final errors = response['message']['errors'] as Map<String, dynamic>;
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.map((e) => e.toString()));
              } else {
                errorMessages.add(value.toString());
              }
            });
            errorMessage = errorMessages.join('\n');
          } else if (response['message']['message'] != null) {
             errorMessage = response['message']['message'].toString();
          } else {
             errorMessage = response['message'].toString();
          }
        }

        state = state.copyWith(
          isSaving: false,
          error: errorMessage,
        );
        
       Toaster.showError(errorMessage);
      }
    } catch (e, st) {
      print("Save error: $e\n$st");
      state = state.copyWith(isSaving: false, error: e.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> assignOrder(
      BuildContext context,
      Map<String, dynamic> payload,
      ) async {
    state = state.copyWith(assignLoad: true, error: null);

    try {
      final response = await ApiClient().post(
         endpoint: "api/common/work-orders/bulk-allocate",
         body: payload,
      );
      print("assignOrder Response: $response");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        if (actualResponse != null && actualResponse["success"] == true) {
          await fetchWorkOrders(urls: state.urls);
          
          state = state.copyWith(
            assignLoad: false,
          );
          
          String successMessage = "Order Allocated";
          if (actualResponse['message'] != null) {
            successMessage = actualResponse['message'].toString();
          }
          Toaster.showSuccess(successMessage);
          
          if (context.mounted) {
            Get.back();
          }
        } else {
          final errMsg = actualResponse?['message']?.toString() ?? 'API success check failed';
          state = state.copyWith(assignLoad: false, error: errMsg);
          Toaster.showError(errMsg);
        }
      } else {
        String errMsg = 'API status failure';
        if (response != null && response['message'] != null) {
          final msgData = response['message'];
          if (msgData is Map) {
            errMsg = msgData['message']?.toString() ?? 'Validation Error';
            if (msgData['errors'] != null && msgData['errors'] is Map) {
              final Map errors = msgData['errors'] as Map;
              if (errors.isNotEmpty) {
                final firstErr = errors.values.first;
                if (firstErr is List && firstErr.isNotEmpty) {
                  errMsg += ": ${firstErr.first}";
                }
              }
            }
          } else {
            errMsg = msgData.toString();
          }
        }
        state = state.copyWith(assignLoad: false, error: errMsg);
        Toaster.showError(errMsg);
      }
    } catch (e, st) {
      print("Save error: $e\n$st");
      state = state.copyWith(assignLoad: false, error: e.toString());
      Toaster.showError("Failed to allocate order: ${e.toString()}");
    }
  }

  Future<bool> approveOrder(
      BuildContext context,
      Map<String, dynamic> payload,
      ) async {
    state = state.copyWith(assignLoad: true, error: null);

    try {
      final response = await ApiClient().post(
         endpoint: "api/common/work-orders/bulk-approve",
         body: payload,
      );
      print("approveOrder Response: $response");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        if (actualResponse != null && actualResponse["success"] == true) {
          await fetchWorkOrders(urls: state.urls);
          
          state = state.copyWith(
            assignLoad: false,
          );
          Get.back();
          String successMessage = "Order Approved";
          if (actualResponse['message'] != null) {
            successMessage = actualResponse['message'].toString();
          }
          Toaster.showSuccess(successMessage);
          
          return true; // Success handling for the dialog
        } else {
          final errMsg = actualResponse?['message']?.toString() ?? 'API success check failed';
          state = state.copyWith(assignLoad: false, error: errMsg);
          Toaster.showError(errMsg);
          return false;
        }
      } else {
        String errMsg = 'API status failure';
        if (response != null && response['message'] != null) {
          final msgData = response['message'];
          if (msgData is Map) {
            errMsg = msgData['message']?.toString() ?? 'Validation Error';
            if (msgData['errors'] != null && msgData['errors'] is Map) {
              final Map errors = msgData['errors'] as Map;
              if (errors.isNotEmpty) {
                final firstErr = errors.values.first;
                if (firstErr is List && firstErr.isNotEmpty) {
                  errMsg += ": ${firstErr.first}";
                }
              }
            }
          } else {
            errMsg = msgData.toString();
          }
        }
        state = state.copyWith(assignLoad: false, error: errMsg);
        Toaster.showError(errMsg);
        return false;
      }
    } catch (e, st) {
      print("Approve error: $e\n$st");
      state = state.copyWith(assignLoad: false, error: e.toString());
      Toaster.showError("Failed to approve order: ${e.toString()}");
      return false;
    }
  }

  Future<void> reallocateWorkOrder(
      BuildContext context,
      String id,
      Map<String, dynamic> payload,
      ) async {
    state = state.copyWith(assignLoad: true, error: null);

    try {
      final response = await ApiClient().post(
        endpoint: "api/common/work-orders/$id/reallocate",
        body: payload,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Order reallocated successfully");
        await fetchWorkOrders(urls: state.urls);
        state = state.copyWith(assignLoad: false);
        if (context.mounted) {
           Navigator.pop(context);
        }
      } else {
        String errMsg = response?["message"]?.toString() ?? "Failed to reallocate order";
        Toaster.showError(errMsg);
        state = state.copyWith(assignLoad: false, error: errMsg);
      }
    } catch (e, st) {
      debugPrint("Reallocate error: $e\n$st");
      state = state.copyWith(assignLoad: false, error: e.toString());
      Toaster.showError("Error: $e");
    }
  }

  Future<void> bulkAcceptWorkOrders(List<int> ids) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/work-orders/bulk-accept",
        body: {"ids": ids},
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders accepted successfully");
        fetchWorkOrders(urls: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to accept orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> bulkRejectWorkOrders(List<int> ids, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/work-orders/bulk-reject",
        body: {
          "ids": ids,
          "rejection_reason": reason,
        },
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders rejected successfully");
        fetchWorkOrders(urls: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to reject orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> bulkCompleteWorkOrders(List<int> ids) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/work-orders/bulk-complete",
        body: {"ids": ids},
      );
      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Orders completed successfully");
        fetchWorkOrders(urls: state.urls);
      } else {
        Toaster.showError(response?["message"] ?? "Failed to complete orders");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }


// riverpod/purchase_orders_notifier.dart

  Future<void> craftmanAction(
      String url,
      BuildContext context,
      Map<String, dynamic> payload,
      {
        String? id = '',
        bool? reject = false,
        bool? complete = false,

      }
      ) async {

    final partnerId = payload["id"].toString();

    // 1. SET LOADING STATE: Use the specific ID for the specific action
    state = state.copyWith(
      error: null,
      craftsmanAcceptId: reject == true ? null : partnerId,
      craftsmanRejectId: reject == true ? partnerId : null,
    );

    try {
      // final response = await Repo().workOrdersPost(
      //   method:"POST",
      //   url ,
      //   payload,
      // );
      final response = {};
      print("$response -------------------------");

      if (response["data"] != null  && response["status"] == 1) {
        await fetchWorkOrders(urls: state.urls);

        state = state.copyWith(
          craftsmanAcceptId: null,
          craftsmanRejectId: null,
        );

        // if (context.mounted && complete == false) {
        //   context.pop();
        // }
      } else {
        throw Exception('Invalid response');
      }
    } catch (e, st) {
      print("Save error: $e\n$st");

      state = state.copyWith(
        craftsmanAcceptId: null,
        craftsmanRejectId: null,
        error: e.toString(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> adminAction(
      String url,
      BuildContext context,
      Map<String, dynamic> payload,
      ) async {
    state = state.copyWith(assignLoad: true, error: null);

    try {
      // final response = await Repo().workOrdersPost(
      //   method:"POST",
      //   url,
      //   payload,
      // );
      final response = {};
      print("$response -------------------------");


      if ( response["status"] == 1) {
        // final newOrder = WorkOrder.fromJson(response["data"]);
        await fetchWorkOrders(urls: state.urls);
        state = state.copyWith(
          assignLoad: false,
        );

        // if (context.mounted) {
        //   // context.pop();
        // MessageController.success(context, response["data"]['message']  );
        //
        // }
      } else {
        throw Exception('Invalid response');
      }
    } catch (e, st) {
      print("Save error: $e\n$st");
      state = state.copyWith(assignLoad: false, error: e.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> workOrderDetail(String? id, BuildContext context) async {
    if (id == null || id.isEmpty || id == "null") {
      state = state.copyWith(isLoading: false, workOrderDetail: null);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/work-orders/$id");
      print("++++ details Response: $response");


      if (response["status"] == 1) {
        print("++++ details Response: $response");

        final productDetail = WorkOrder.fromJson(response["data"]?["data"]);
        print("++++ details Response: hello $productDetail");
        state = state.copyWith(
          isLoading: false,
          error: null,
          workOrderDetail: productDetail,
        );
      } else {
        print("this is a end: ${state.workOrderDetail}");
        state = state.copyWith(
          isLoading: false,
          error: null,
          workOrderDetail: null,
        );
        throw Exception('Invalid response from details API');
      }
    } catch (e, stackTrace) {
      print("Stack trace: $stackTrace");
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load product details: ${e.toString()}",
        workOrderDetail: null,
      );
    }
  }

  void filterBuyers(String filterKey, String query) {
    if (query.isEmpty) {
      state = state.copyWith(workOrders: state.allWorkOrders);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredList = state.allWorkOrders.where((catalogue) {
      switch (filterKey) {
        case 'Buyer Code':
          return (catalogue.bpCode ?? '').toLowerCase().contains(lowerQuery);
        case 'Buyer Name':
          return (catalogue.productName ?? '').toLowerCase().contains(lowerQuery);
        // case 'Mobile':
        //   return (catalogue.productCategory ?? '').toLowerCase().contains(lowerQuery);
        case 'Email':
          return (catalogue.productCode ?? '').toLowerCase().contains(lowerQuery);
        default:
          return false;
      }
    }).toList();

    state = state.copyWith(workOrders: filteredList);
  }

  void sortBuyers(String sortKey, {bool ascending = true}) {
    final currentList = List<WorkOrder>.from(state.workOrders);

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
        // case 'productCategory':
        //   result = compare(a.productCategory, b.productCategory);
          break;
        case 'productCode':
          result = compare(a.productCode, b.productCode);
          break;
      }

      return ascending ? result : -result;
    });

    state = state.copyWith(workOrders: currentList);
  }
  void resetCataloguesPartners() {
    state = state.copyWith(
      workOrders: state.allWorkOrders,
      error: null,
      isLoaded: true,
    );
  }
}

final workOrderListProvider = StateNotifierProvider<WorkOrderListNotifier, WorkOrderListState>(
      (ref) => WorkOrderListNotifier(ref),
);