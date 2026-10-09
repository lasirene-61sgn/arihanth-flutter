import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/screens/reports/model/report_model.dart';
import 'package:flutter/foundation.dart';

class ReportState {
  final bool isLoading;
  final ReportModel? reportData;
  final String? error;

  const ReportState({
    this.isLoading = false,
    this.reportData,
    this.error,
  });

  ReportState copyWith({
    bool? isLoading,
    ReportModel? reportData,
    String? error,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      reportData: reportData ?? this.reportData,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier() : super(const ReportState());

  Future<void> fetchReportDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: "api/common/dashboard/details");
      if (response != null && (response['status'] == 1 || response['status'] == true)) {
        final innerData = response['data'] ?? {};
        if (innerData['success'] == true) {
          final actualData = innerData['data'] ?? {};
          state = state.copyWith(
            isLoading: false,
            reportData: ReportModel.fromJson(actualData),
          );
        } else {
          final message = innerData['message']?.toString() ?? "Failed to fetch report details";
          state = state.copyWith(isLoading: false, error: message);
        }
      } else {
        final message = response?['message']?.toString() ?? "Failed to fetch report details";
        state = state.copyWith(isLoading: false, error: message);
      }
    } catch (e, st) {
      debugPrint("Error fetching report details: $e\n$st");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  void reorderTopPicksCraftsman(int oldIndex, int newIndex) {
    if (state.reportData == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final list = List<TopPicksCraftsman>.from(state.reportData!.topPicksCraftsman);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    final newData = ReportModel(
      topPicksCraftsman: list,
      topPicksClient: state.reportData!.topPicksClient,
      overallDesigns: state.reportData!.overallDesigns,
      craftsmanFavorites: state.reportData!.craftsmanFavorites,
      buyerFavorites: state.reportData!.buyerFavorites,
    );
    state = state.copyWith(reportData: newData);
  }

  void reorderTopPicksClient(int oldIndex, int newIndex) {
    if (state.reportData == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final list = List<TopPicksClient>.from(state.reportData!.topPicksClient);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    final newData = ReportModel(
      topPicksCraftsman: state.reportData!.topPicksCraftsman,
      topPicksClient: list,
      overallDesigns: state.reportData!.overallDesigns,
      craftsmanFavorites: state.reportData!.craftsmanFavorites,
      buyerFavorites: state.reportData!.buyerFavorites,
    );
    state = state.copyWith(reportData: newData);
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier();
});
