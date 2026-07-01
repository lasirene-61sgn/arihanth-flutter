import 'package:arianth/screens/dashboard_screen/model/dashboard_model.dart';
import 'package:arianth/screens/dashboard_screen/model/new_update_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Updated DashboardState to hold DashboardModel
class DashboardState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final DashboardModel? dashboardData;
  final List<NewUpdateModel>? newUpdates;

  const DashboardState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.dashboardData,
    this.newUpdates,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    DashboardModel? dashboardData,
    List<NewUpdateModel>? newUpdates,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      dashboardData: dashboardData ?? this.dashboardData,
      newUpdates: newUpdates ?? this.newUpdates,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState());
  Future<void> fetchDashBoard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient()
          .get(endpoint: "api/common/dashboard/stats");

      print("++++ Dashboard API Response: $response");

      List<NewUpdateModel>? newUpdates;
      try {
        final updateResponse = await ApiClient().get(endpoint: "api/common/new-updates");
        print("++++ New Updates API Response: $updateResponse");
        if (updateResponse["status"] == 1 && updateResponse["data"] != null) {
          final dataList = updateResponse["data"]["data"];
          if (dataList is List && dataList.isNotEmpty) {
            newUpdates = dataList
                .map((item) => NewUpdateModel.fromJson(item))
                .toList();
          }
        }
      } catch (e) {
        print("New updates fetch error: $e");
      }

      if (response["status"] == 1) {
        final dashboard =
        DashboardModel.fromJson(response["data"]);

        print("++++ Parsed Dashboard: $dashboard");

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          dashboardData: dashboard,
          newUpdates: newUpdates,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoaded: false,
          newUpdates: newUpdates,
        );
      }
    } catch (e, st) {
      print("Dashboard fetch error: $e");
      print(st);

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: e.toString(),
      );
    }
  }
}


// 3. Riverpod Provider
final dashboardProvider =
StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(),
);