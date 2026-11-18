import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import '../../../services/widget/custom_msg.dart';
import '../model/repair_model.dart';




class RepairListState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<RepairOrder> repairs;
  final RepairOrder? repairDetail;
  final bool isAccepting;
  final bool isApproving;
  final bool isRejecting;
  final bool isAllocating;
  final bool isCompleting;
  final bool isBuyerCompleting;
  final bool isBuyerAccepting;
  final String? activeActionRepairId;
  final String? activeActionType; // 'accept', 'approve', 'reject', 'allocate', 'complete', 'buyer_complete', 'buyer_accept'
  final int currentPage;
  final String? nextUrl;
  final String? previousUrl;
  final int? count;
  final Map<String, int> counts;
  final String activeTab;
  final String? role;

  RepairListState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isAccepting = false,
    this.isApproving = false,
    this.isRejecting = false,
    this.isAllocating = false,
    this.isCompleting = false,
    this.isBuyerCompleting = false,
    this.isBuyerAccepting = false,
    this.activeActionRepairId,
    this.activeActionType,
    this.error,
    this.repairs = const [],
    this.repairDetail,
    this.currentPage = 1,
    this.nextUrl,
    this.previousUrl,
    this.count,
    this.counts = const {},
    this.activeTab = 'all',
    this.role,
  });

  RepairListState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<RepairOrder>? repairs,
    RepairOrder? repairDetail,
    bool clearRepairDetail = false,
    bool? isAccepting,
    bool? isApproving,
    bool? isRejecting,
    bool? isAllocating,
    bool? isCompleting,
    bool? isBuyerCompleting,
    bool? isBuyerAccepting,
    dynamic activeActionRepairId = _sentinel,
    dynamic activeActionType = _sentinel,
    int? currentPage,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    dynamic count = _sentinel,
    Map<String, int>? counts,
    String? activeTab,
    String? role,
  }) {
    return RepairListState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isAccepting: isAccepting ?? this.isAccepting,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
      isAllocating: isAllocating ?? this.isAllocating,
      isCompleting: isCompleting ?? this.isCompleting,
      isBuyerCompleting: isBuyerCompleting ?? this.isBuyerCompleting,
      isBuyerAccepting: isBuyerAccepting ?? this.isBuyerAccepting,
      activeActionRepairId: activeActionRepairId == _sentinel ? this.activeActionRepairId : activeActionRepairId as String?,
      activeActionType: activeActionType == _sentinel ? this.activeActionType : activeActionType as String?,
      error: error ?? this.error,
      repairs: repairs ?? this.repairs,
      repairDetail: clearRepairDetail ? null : repairDetail ?? this.repairDetail,
      currentPage: currentPage ?? this.currentPage,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      count: count == _sentinel ? this.count : count as int?,
      counts: counts ?? this.counts,
      activeTab: activeTab ?? this.activeTab,
      role: role ?? this.role,
    );
  }
}

const _sentinel = Object();

class RepairListNotifier extends StateNotifier<RepairListState> {
  RepairListNotifier() : super(RepairListState());

  Future<void> fetchRepairs({String? customUrl, String? tab}) async {
    state = state.copyWith(isLoading: true, error: null);

    final effectiveTab = tab ?? state.activeTab;
    String endpoint = customUrl ?? 'api/common/repairs';
    // Append tab filter if not already present in custom URL
    if (customUrl == null) {
      if (effectiveTab.isNotEmpty && effectiveTab != 'all') {
        endpoint = 'api/common/repairs?tab=$effectiveTab';
      } else {
        endpoint = 'api/common/repairs?tab=all';
      }
    }

    try {
      final response = await ApiClient().get(endpoint: endpoint);

      if (response != null && response['status'] == 1 && response['data'] != null) {
        final responseData = response['data'];

        if (responseData['success'] == true) {
          // Parse tab counts from API — preserve existing counts if new response has none
          Map<String, int> newCounts = Map<String, int>.from(state.counts);
          if (responseData['counts'] is Map) {
            final rawCounts = responseData['counts'] as Map;
            rawCounts.forEach((k, v) {
              newCounts[k.toString()] = (v as num?)?.toInt() ?? 0;
            });
          }

          final String activeTab = tab ??
              (responseData['active_tab']?.toString().isNotEmpty == true
                  ? responseData['active_tab'].toString()
                  : state.activeTab);
          final String? role = responseData['role']?.toString();

          // Parse paginated list data
          List<RepairOrder> loadedRepairs = [];
          int currentPage = 1;
          String? next;
          String? prev;
          int? count;

          final dataObj = responseData['data'];
          if (dataObj is Map) {
            currentPage = (dataObj['current_page'] as num?)?.toInt() ?? 1;
            next = dataObj['next_page_url'] as String?;
            prev = dataObj['prev_page_url'] as String?;
            // Laravel pagination uses 'total'; fallback to 'count'
            count = (dataObj['total'] as num?)?.toInt() ??
                    (dataObj['count'] as num?)?.toInt();

            final rawList = dataObj['data'];
            if (rawList is List) {
              loadedRepairs = rawList
                  .map((json) =>
                      RepairOrder.fromJson(json as Map<String, dynamic>))
                  .toList();
            }
          } else if (dataObj is List) {
            // Direct list (non-paginated)
            loadedRepairs = dataObj
                .map((json) =>
                    RepairOrder.fromJson(json as Map<String, dynamic>))
                .toList();
            count = loadedRepairs.length;
          }

          print("FETCH_REPAIRS SUCCESS: tab=$activeTab, count=${loadedRepairs.length}, total=$count");

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            repairs: loadedRepairs,
            currentPage: currentPage,
            nextUrl: next,
            previousUrl: prev,
            count: count,
            counts: newCounts,
            activeTab: activeTab,
            role: role,
          );
        } else {
          // API returned success: false
          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            repairs: [],
            error: responseData['message']?.toString() ??
                'Failed to load repair orders.',
          );
        }
      } else {
        // Non-200 or missing data
        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          repairs: [],
          error: response?['data']?['message']?.toString() ??
              response?['message']?.toString() ??
              'Failed to load repair orders.',
        );
      }
    } catch (e, st) {
      debugPrint('fetchRepairs error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        isLoaded: true,
        repairs: [],
        error: e.toString(),
      );
    }
  }

  /// Switch tab — clears stale list immediately so spinner shows during fetch.
  void changeTab(String tab) {
    state = state.copyWith(
      activeTab: tab,
      isLoaded: false,
      repairs: [],
      nextUrl: null,
      previousUrl: null,
      count: null,
      error: null,
    );
    fetchRepairs(tab: tab);
  }

  void goToNextPage() {
    if (state.nextUrl != null) {
      String endpoint = state.nextUrl!;
      if (endpoint.startsWith('/')) {
        endpoint = endpoint.substring(1);
      }
      fetchRepairs(customUrl: endpoint);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      String endpoint = state.previousUrl!;
      if (endpoint.startsWith('/')) {
        endpoint = endpoint.substring(1);
      }
      fetchRepairs(customUrl: endpoint);
    }
  }

  Future<void> createRepair(
    Map<String, dynamic> payload, {
    PlatformFile? imageFile,
    String imageFieldName = 'repair_image',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        method: "POST",
        endpoint: "api/common/repairs",
        fields: payload,
        files: imageFile != null ? {imageFieldName: imageFile} : null,
      );

      if (response != null && response["status"] == 1) {
        final orderId = response["data"]?["data"]?["id"]?.toString() ?? "";
        await fetchRepairs();
        Get.offNamed(AppRoutes.orderSuccess, arguments: {
          'orderNo': orderId,
          'orderType': 'Sample/Repair Order',
          'onBack': () => Get.back(),
        });
      } else {
        String errMsg = response?["message"]?.toString() ?? "Failed to create repair order";
        Toaster.showError(errMsg);
        state = state.copyWith(isLoading: false, error: errMsg);
      }
    } catch (e) {

      Toaster.showError("Error: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateRepair(
    String id,
    Map<String, dynamic> payload, {
    PlatformFile? imageFile,
    String imageFieldName = 'repair_image',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        endpoint: "api/common/repairs/$id",
        fields: payload,
        files: imageFile != null ? {imageFieldName: imageFile} : null,
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Repair order updated successfully");
        await fetchRepairs();
        Get.back();
      } else {
        String errMsg = response?["message"]?.toString() ?? "Failed to update repair order";
        Toaster.showError(errMsg);
        state = state.copyWith(isLoading: false, error: errMsg);
      }
    } catch (e) {

      Toaster.showError("Error: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Actions ---

  Future<bool> acceptRepair(String id) async {
    return _performAction(
      'api/common/repairs/$id/accept',
      {},
      repairId: id,
      actionFlag: 'accepting',
      actionType: 'accept',
    );
  }

  Future<bool> approveRepair(String id, {String? itemSentBy}) async {
    return _performAction(
      'api/common/repairs/$id/approve',
      {
        if (itemSentBy != null && itemSentBy.isNotEmpty) 'item_sent_by': itemSentBy,
      },
      repairId: id,
      actionFlag: 'approving',
      actionType: 'approve',
    );
  }

  Future<bool> rejectRepair(String id, String reason) async {
    return _performAction(
      'api/common/repairs/$id/reject',
      {'reject_reason': reason},
      repairId: id,
      actionFlag: 'rejecting',
      actionType: 'reject',
    );
  }

  Future<bool> allocateRepair(
    String id, {
    required String craftsmanCode,
    String? itemSentBy,
    String? notes,
  }) async {
    return _performAction(
      'api/common/repairs/$id/allocate',
      {
        'craftman_code': craftsmanCode,
        'craftsman_code': craftsmanCode, // support both field spellings
        if (itemSentBy != null && itemSentBy.isNotEmpty) 'item_sent_by': itemSentBy,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (notes != null && notes.isNotEmpty) 'note': notes,
      },
      repairId: id,
      actionFlag: 'allocating',
      actionType: 'allocate',
    );
  }

  Future<bool> completeRepair(
    String id, {
    String? itemCollectedBy,
    String? itemReturnedBy,
    PlatformFile? craftsmanVoucherImage,
    PlatformFile? craftsmanCompletionProofImage,
  }) async {
    final fields = <String, dynamic>{
      if (itemCollectedBy != null && itemCollectedBy.isNotEmpty)
        'item_collected_by': itemCollectedBy,
      if (itemReturnedBy != null && itemReturnedBy.isNotEmpty)
        'item_returned_by': itemReturnedBy,
    };

    final files = <String, dynamic>{
      if (craftsmanVoucherImage != null)
        'craftsman_voucher_image': craftsmanVoucherImage,
      if (craftsmanCompletionProofImage != null)
        'craftsman_completion_proof_image': craftsmanCompletionProofImage,
    };

    if (files.isNotEmpty) {
      return _performActionWithFiles(
        'api/common/repairs/$id/complete',
        fields,
        files: files,
        repairId: id,
        actionFlag: 'completing',
        actionType: 'complete',
      );
    }

    return _performAction(
      'api/common/repairs/$id/complete',
      fields,
      repairId: id,
      actionFlag: 'completing',
      actionType: 'complete',
    );
  }

  Future<bool> buyerCompleteRepair(
    String id, {
    String? itemCollectedBy,
    String? itemReturnedBy,
    PlatformFile? buyerVoucherImage,
    PlatformFile? buyerCompletionProofImage,
  }) async {
    final fields = <String, dynamic>{
      if (itemCollectedBy != null && itemCollectedBy.isNotEmpty)
        'item_collected_by': itemCollectedBy,
      if (itemReturnedBy != null && itemReturnedBy.isNotEmpty)
        'item_returned_by': itemReturnedBy,
    };

    final files = <String, dynamic>{
      if (buyerVoucherImage != null)
        'buyer_voucher_image': buyerVoucherImage,
      if (buyerCompletionProofImage != null)
        'buyer_completion_proof_image': buyerCompletionProofImage,
    };

    if (files.isNotEmpty) {
      return _performActionWithFiles(
        'api/common/repairs/$id/buyer-complete',
        fields,
        files: files,
        repairId: id,
        actionFlag: 'buyerCompleting',
        actionType: 'buyer_complete',
      );
    }

    return _performAction(
      'api/common/repairs/$id/buyer-complete',
      fields,
      repairId: id,
      actionFlag: 'buyerCompleting',
      actionType: 'buyer_complete',
    );
  }

  Future<bool> buyerAcceptRepair(String id, {String? itemAcceptedBy}) async {
    return _performAction(
      'api/common/repairs/$id/buyer-accept',
      {
        if (itemAcceptedBy != null && itemAcceptedBy.isNotEmpty)
          'item_accepted_by': itemAcceptedBy,
      },
      repairId: id,
      actionFlag: 'buyerAccepting',
      actionType: 'buyer_accept',
    );
  }

  Future<bool> buyerRejectRepair(String id, String reason) async {
    return _performAction(
      'api/common/repairs/$id/buyer-reject',
      {'reject_reason': reason},
      repairId: id,
      actionFlag: 'rejecting',
      actionType: 'reject',
    );
  }

  Future<bool> _performAction(
    String endpoint,
    Map<String, dynamic> body, {
    String? repairId,
    String? actionFlag,
    String? actionType,
    String? successMessage,
  }) async {
    // Set individual flag and active action
    state = state.copyWith(
      activeActionRepairId: repairId,
      activeActionType: actionType,
      isAccepting: actionFlag == 'accepting' ? true : null,
      isApproving: actionFlag == 'approving' ? true : null,
      isRejecting: actionFlag == 'rejecting' ? true : null,
      isAllocating: actionFlag == 'allocating' ? true : null,
      isCompleting: actionFlag == 'completing' ? true : null,
      isBuyerCompleting: actionFlag == 'buyerCompleting' ? true : null,
      isBuyerAccepting: actionFlag == 'buyerAccepting' ? true : null,
      error: null,
    );
    try {
      final response = await ApiClient().post(endpoint: endpoint, body: body);

      if (response != null && response['status'] == 1) {
        final msg = response['message']?.toString() ??
            response['data']?['message']?.toString() ??
            successMessage ??
            "Action completed successfully";
        Toaster.showSuccess(msg);
        _resetActionFlags();
        await fetchRepairs(tab: state.activeTab);
        return true;
      } else {
        String errMsg = "Action failed";
        if (response != null && response['message'] != null) {
          errMsg = response['message'].toString();
        } else if (response != null &&
            response['data'] != null &&
            response['data']['message'] != null) {
          errMsg = response['data']['message'].toString();
        }
        Toaster.showError(errMsg);
        _resetActionFlags();
        state = state.copyWith(isLoading: false, error: errMsg);
        return false;
      }
    } catch (e) {
      final errMsg = e.toString();
      Toaster.showError("Error: $errMsg");
      _resetActionFlags();
      state = state.copyWith(isLoading: false, error: errMsg);
      return false;
    }
  }

  Future<bool> _performActionWithFiles(
    String endpoint,
    Map<String, dynamic> fields, {
    Map<String, dynamic>? files,
    String? repairId,
    String? actionFlag,
    String? actionType,
    String? successMessage,
  }) async {
    state = state.copyWith(
      activeActionRepairId: repairId,
      activeActionType: actionType,
      isCompleting: actionFlag == 'completing' ? true : null,
      isBuyerCompleting: actionFlag == 'buyerCompleting' ? true : null,
      error: null,
    );
    try {
      final response = await ApiClient().requestWithFiles(
        endpoint: endpoint,
        fields: fields,
        files: files,
      );

      if (response != null && response['status'] == 1) {
        final msg = response['message']?.toString() ??
            response['data']?['message']?.toString() ??
            successMessage ??
            "Action completed successfully";
        Toaster.showSuccess(msg);
        _resetActionFlags();
        await fetchRepairs(tab: state.activeTab);
        return true;
      } else {
        String errMsg = "Action failed";
        if (response != null && response['message'] != null) {
          errMsg = response['message'].toString();
        } else if (response != null &&
            response['data'] != null &&
            response['data']['message'] != null) {
          errMsg = response['data']['message'].toString();
        }
        Toaster.showError(errMsg);
        _resetActionFlags();
        state = state.copyWith(isLoading: false, error: errMsg);
        return false;
      }
    } catch (e) {
      final errMsg = e.toString();
      Toaster.showError("Error: $errMsg");
      _resetActionFlags();
      state = state.copyWith(isLoading: false, error: errMsg);
      return false;
    }
  }

  void _resetActionFlags() {
    state = state.copyWith(
      isLoading: false,
      isAccepting: false,
      isApproving: false,
      isRejecting: false,
      isAllocating: false,
      isCompleting: false,
      isBuyerCompleting: false,
      isBuyerAccepting: false,
      activeActionRepairId: null,
      activeActionType: null,
    );
  }

  Future<void> fetchRepairDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: 'api/common/repairs/$id');


      if (response != null && response['status'] == 1 && response['data'] != null) {
        final responseData = response['data'];
        if (responseData['success'] == true && responseData['data'] != null) {
          final repair = RepairOrder.fromJson(responseData['data']);
          state = state.copyWith(
            isLoading: false,
            repairDetail: repair,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: responseData['message']?.toString() ?? "Repair not found",
            clearRepairDetail: true,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response?['message']?.toString() ?? "Failed to load repair details",
          clearRepairDetail: true,
        );
      }
    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearRepairDetail: true,
      );
    }
  }

  void clearRepairDetail() {
    state = state.copyWith(clearRepairDetail: true);
  }
}

final repairListProvider = StateNotifierProvider<RepairListNotifier, RepairListState>((ref) {
  return RepairListNotifier();
});
