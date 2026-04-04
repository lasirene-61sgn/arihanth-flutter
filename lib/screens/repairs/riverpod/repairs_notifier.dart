import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:file_picker/file_picker.dart';
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
  final bool isRejecting;
  final bool isAllocating;
  final bool isCompleting;
  final int currentPage;
  final String? nextUrl;
  final String? previousUrl;
  final int? count;

  RepairListState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isAccepting = false,
    this.isRejecting = false,
    this.isAllocating = false,
    this.isCompleting = false,
    this.error,
    this.repairs = const [],
    this.repairDetail,
    this.currentPage = 1,
    this.nextUrl,
    this.previousUrl,
    this.count,
  });

  RepairListState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<RepairOrder>? repairs,
    RepairOrder? repairDetail,
    bool clearRepairDetail = false,
    bool? isAccepting,
    bool? isRejecting,
    bool? isAllocating,
    bool? isCompleting,
    int? currentPage,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    dynamic count = _sentinel,
  }) {
    return RepairListState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isAccepting: isAccepting ?? this.isAccepting,
      isRejecting: isRejecting ?? this.isRejecting,
      isAllocating: isAllocating ?? this.isAllocating,
      isCompleting: isCompleting ?? this.isCompleting,
      error: error ?? this.error,
      repairs: repairs ?? this.repairs,
      repairDetail: clearRepairDetail ? null : repairDetail ?? this.repairDetail,
      currentPage: currentPage ?? this.currentPage,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      count: count == _sentinel ? this.count : count as int?,
    );
  }
}

const _sentinel = Object();

class RepairListNotifier extends StateNotifier<RepairListState> {
  RepairListNotifier() : super(RepairListState());

  Future<void> fetchRepairs({String? customUrl}) async {
    state = state.copyWith(isLoading: true, error: null);

    String endpoint = customUrl ?? 'api/common/repairs';

    try {
      final response = await ApiClient().get(endpoint: endpoint);


      if (response != null && response['status'] == 1 && response['data'] != null) {
        final responseData = response['data'];
        
        if (responseData['success'] == true) {
          // Parse list data
          List<RepairOrder> loadedRepairs = [];
          int currentPage = 1;
          String? next;
          String? prev;
          int? count;

          if (responseData['data'] != null) {
            final dataObj = responseData['data'];
            currentPage = dataObj['current_page'] ?? 1;
            next = dataObj['next_page_url'];
            prev = dataObj['prev_page_url'];
            count = dataObj['count'] ?? 0;

            if (dataObj['data'] != null) {
              final List<dynamic> dataList = dataObj['data'];
              loadedRepairs = dataList.map((json) => RepairOrder.fromJson(json)).toList();
            }
          }

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            repairs: loadedRepairs,
            currentPage: currentPage,
            nextUrl: next,
            previousUrl: prev,
            count: count,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: responseData['message']?.toString() ?? "Failed to load repair orders.",
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response?['message']?.toString() ?? "Failed to load repair orders.",
        );
      }
    } catch (e) {

      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        method: "POST",
        endpoint: "api/common/repairs",
        fields: payload,
        files: imageFile != null ? {'image_proof': imageFile} : null,
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        endpoint: "api/common/repairs/$id",
        fields:payload,
        files: imageFile != null ? {'image_proof': imageFile} : null,
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
    return _performAction('api/common/repairs/$id/accept', {}, actionFlag: 'accepting');
  }

  Future<bool> rejectRepair(String id, String reason) async {
    return _performAction('api/common/repairs/$id/reject', {'reject_reason': reason}, actionFlag: 'rejecting');
  }

  Future<bool> allocateRepair(String id, String craftsmanCode, String notes) async {
    return _performAction('api/common/repairs/$id/allocate', {
      'craftsman_code': craftsmanCode,
      'note': notes
    }, actionFlag: 'allocating');
  }

  Future<bool> completeRepair(String id) async {
    return _performAction('api/common/repairs/$id/complete', {}, actionFlag: 'completing');
  }

  Future<bool> buyerAcceptRepair(String id) async {
    return _performAction('api/common/repairs/$id/buyer-accept', {}, actionFlag: 'accepting');
  }

  Future<bool> buyerRejectRepair(String id, String reason) async {
    return _performAction('api/common/repairs/$id/buyer-reject', {'reject_reason': reason}, actionFlag: 'rejecting');
  }

  Future<bool> _performAction(String endpoint, Map<String, dynamic> body, {String? actionFlag}) async {
    // Set individual flag
    if (actionFlag == 'accepting') state = state.copyWith(isAccepting: true);
    if (actionFlag == 'rejecting') state = state.copyWith(isRejecting: true);
    if (actionFlag == 'allocating') state = state.copyWith(isAllocating: true);
    if (actionFlag == 'completing') state = state.copyWith(isCompleting: true);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(endpoint: endpoint, body: body);

      if (response != null && response['status'] == 1) {
        // Reset flags and refresh
        _resetActionFlags();
        await fetchRepairs();
        return true;
      } else {
        String errMsg = "Action failed";
        if (response != null && response['message'] != null) {
          errMsg = response['message'].toString();
        } else if (response != null && response['data'] != null && response['data']['message'] != null) {
          errMsg = response['data']['message'].toString();
        }
        _resetActionFlags();
        state = state.copyWith(isLoading: false, error: errMsg);
        return false;
      }
    } catch (e) {

      _resetActionFlags();
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void _resetActionFlags() {
    state = state.copyWith(
      isLoading: false,
      isAccepting: false,
      isRejecting: false,
      isAllocating: false,
      isCompleting: false,
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
