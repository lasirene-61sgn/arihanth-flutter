import 'package:arianth/screens/dashboard_screen/model/dashboard_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Updated DashboardState to hold DashboardModel
class DashboardState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final DashboardModel? dashboardData;

  const DashboardState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.dashboardData,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    DashboardModel? dashboardData,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      dashboardData: dashboardData ?? this.dashboardData,
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

      if (response["status"] == 1) {
        final dashboard =
        DashboardModel.fromJson(response["data"]);

        print("++++ Parsed Dashboard: $dashboard");

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          dashboardData: dashboard,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoaded: false,
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