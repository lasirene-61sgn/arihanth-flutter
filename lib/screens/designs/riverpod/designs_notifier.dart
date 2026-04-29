import 'dart:convert';
import 'dart:io';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';



class DesignListState {
  final bool isLoading;
  final String? savingDesignId;
  final String? rejectingDesignId;
  final bool isLoaded;
  final bool isSaving;
  final String? error;
  final List<Design> designs;
  final List<Design> allDesigns;
  final Design? designDetails;
  final int count;
  final String? nextUrl;
  final String? previousUrl;
  final String? currentUrl;
  final bool isBulkAcceptLoading;
  final bool isBulkRejectLoading;

  const DesignListState({
    this.isLoading = false,
    this.savingDesignId,
    this.rejectingDesignId,
    this.isLoaded = false,
    this.isSaving = false,
    this.error,
    this.designs = const [],
    this.allDesigns = const [],
    this.designDetails,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
    this.currentUrl,
    this.isBulkAcceptLoading = false,
    this.isBulkRejectLoading = false,
  });

  DesignListState copyWith({
    bool? isLoading,
    String? savingDesignId,
    String? rejectingDesignId,
    bool? isLoaded,
    bool? isSaving,
    String? error,
    List<Design>? designs,
    List<Design>? allDesigns,
    Design? designDetails,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    String? currentUrl,
    bool? isBulkAcceptLoading,
    bool? isBulkRejectLoading,
  }) {
    return DesignListState(
      isLoading: isLoading ?? this.isLoading,
      savingDesignId: savingDesignId ?? this.savingDesignId,
      rejectingDesignId: rejectingDesignId ?? this.rejectingDesignId,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      designs: designs ?? this.designs,
      allDesigns: allDesigns ?? this.allDesigns,
      designDetails: designDetails ?? this.designDetails,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      currentUrl: currentUrl ?? this.currentUrl,
      isBulkAcceptLoading: isBulkAcceptLoading ?? this.isBulkAcceptLoading,
      isBulkRejectLoading: isBulkRejectLoading ?? this.isBulkRejectLoading,
    );
  }
}

const _sentinel = Object();

class DesignListNotifier extends StateNotifier<DesignListState> {
  final Ref ref;
  DesignListNotifier(this.ref) : super(const DesignListState());

  void goToNextPage() {
    if (state.nextUrl != null) {
      fetchDesigns(url: ApiClient.toRelativeUrl(state.nextUrl!));
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      fetchDesigns(url: ApiClient.toRelativeUrl(state.previousUrl!));
    }
  }

  Future<void> fetchDesigns({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    final String endpoint = url ?? "api/common/designs";

    try {
      final response = await ApiClient().get(endpoint: endpoint);


      final outerData = response["data"];
      final bool isSuccess = outerData != null && outerData["success"] == true;

      if (isSuccess) {
        final paginationData = outerData["data"]; // pagination map
        final dynamic rawList = paginationData?["data"];

        if (rawList != null && rawList is List) {
          final designs = rawList.map((item) => Design.fromJson(item as Map<String, dynamic>)).toList();


          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            designs: designs,
            allDesigns: designs,
            count: paginationData?["total"] ?? designs.length,
            nextUrl: paginationData?["next_page_url"]?.toString(),
            previousUrl: paginationData?["prev_page_url"]?.toString(),
            currentUrl: endpoint,
          );
        } else {

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            designs: [],
            allDesigns: [],
          );
        }
      } else {
        final errorMsg = outerData?["message"]?.toString() ?? "Server returned success: false";

        state = state.copyWith(
          isLoading: false,
          isLoaded: false,
          error: errorMsg,
          designs: [],
        );
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: "Failed to load data: ${e.toString()}",
        designs: [],
      );
    }
  }

  Future<Map<String, dynamic>> saveDesign(
    Map<String, dynamic> map, {
    String? id = '',
    String? url = '',
    bool? reject = false,
  }) async {
    // Use the explicit `id` param (the dialog passes design_code in map, not id)
    final designId = id?.isNotEmpty == true ? id! : map['id']?.toString();
    if (designId == null || designId.isEmpty) {
      return {'success': false, 'message': 'Design ID is missing.'};
    }

    state = state.copyWith(
      savingDesignId: reject == true ? null : designId,
      rejectingDesignId: reject == true ? designId : null,
      error: null,
    );

    try {
      final response = await ApiClient().post(
        endpoint: url,
        body: map,
      );
      print("design Accept Or Reject Response: $response");

      // Response: {status: 1, data: {success: true, message: "...", data: {...}}}
      final outerData = response['data'];
      final isSuccess = response['status'] == 1 && outerData != null && outerData['success'] == true;
      final message = outerData?['message']?.toString() ?? (isSuccess ? 'Done!' : 'Something went wrong.');

      if (isSuccess) {
        await fetchDesigns(url: "api/common/designs?tab=pending");
        Get.back();
        Toaster.showSuccess(message);
        await ref.read(dashboardProvider.notifier).fetchDashBoard();
      }else{
        Toaster.showError(message);
      }

      state = state.copyWith(
        savingDesignId: null,
        rejectingDesignId: null,
        error: isSuccess ? null : message,
      );

      return {'success': isSuccess, 'message': message};
    } catch (e, stackTrace) {

      state = state.copyWith(
        savingDesignId: null,
        rejectingDesignId: null,
        error: e.toString(),
      );
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> designDetail(String id) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/designs/$id");
      final outerData = response["data"];

      if (outerData != null && outerData["success"] == true && outerData["data"] != null) {
        final design = Design.fromJson(outerData["data"]);
        state = state.copyWith(
          isSaving: false,
          error: null,
          designDetails: design,
        );
      } else {
        final errorMsg = outerData?["message"]?.toString() ?? "Design not found";
        state = state.copyWith(isSaving: false, error: errorMsg);
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isSaving: false,
        error: "Failed to load design details: ${e.toString()}",
      );
    }
  }

  void filterDesigns(String query) {
    if (query.isEmpty) {
      state = state.copyWith(designs: state.allDesigns);
      return;
    }
    final lowerQuery = query.toLowerCase();
    final filtered = state.allDesigns.where((d) {
      return (d.designCode ?? '').toLowerCase().contains(lowerQuery) ||
          (d.bpCode ?? '').toLowerCase().contains(lowerQuery)
          // ||
          // (d.product?.productCode ?? '').toLowerCase().contains(lowerQuery)
      ;
    }).toList();
    state = state.copyWith(designs: filtered);
  }

  void resetDesigns() {
    state = state.copyWith(
      designs: state.allDesigns,
      error: null,
      isLoaded: true,
    );
  }

  Future<void> bulkAccept(String ids) async {
    state = state.copyWith(isBulkAcceptLoading: true, error: null);
    try {
      final List<int> idList = ids.split(',').map((e) => int.parse(e.trim())).toList();
      final response = await ApiClient().post(
        endpoint: "api/common/designs/bulk-accept",
        body: {"ids": idList},
      );
      if (response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Designs accepted successfully");
        await fetchDesigns(url: "api/common/designs?tab=pending");
        await ref.read(dashboardProvider.notifier).fetchDashBoard();
      } else {
        Toaster.showError(_extractErrorMessage(response));
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isBulkAcceptLoading: false);
    }
  }

  Future<void> bulkReject(String ids) async {
    state = state.copyWith(isBulkRejectLoading: true, error: null);
    try {
      final List<int> idList = ids.split(',').map((e) => int.parse(e.trim())).toList();
      final response = await ApiClient().post(
        endpoint: "api/common/designs/bulk-reject",
        body: {"ids": idList},
      );
      print("bulk reject :$response");
      if (response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Designs rejected successfully");
        await fetchDesigns(url: "api/common/designs?tab=pending");
        await ref.read(dashboardProvider.notifier).fetchDashBoard();
      } else {
        Toaster.showError(_extractErrorMessage(response));
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    } finally {
      state = state.copyWith(isBulkRejectLoading: false);
    }
  }

  String _extractErrorMessage(dynamic response) {
    if (response == null) return "Unknown error";
    if (response["message"] != null) {
      final msg = response["message"];
      if (msg is Map && msg["message"] != null) {
        return msg["message"].toString();
      }
      return msg.toString();
    }
    if (response["data"] != null && response["data"] is Map && response["data"]["message"] != null) {
      return response["data"]["message"].toString();
    }
    return "Failed to process request";
  }
}

final designsProvider = StateNotifierProvider<DesignListNotifier, DesignListState>(
  (ref) => DesignListNotifier(ref),
);

