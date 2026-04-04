
import 'package:arianth/services/pincode_service/pin_code_model.dart';
import 'package:arianth/services/pincode_service/pincode_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/legacy.dart';


class LocationNotifier extends StateNotifier<LocationState> {
  final PincodeApiService _pincodeService = PincodeApiService();

  LocationNotifier() : super(LocationState());

  Future<void> fetchPincodeDetails(String pincode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final postOffices = await _pincodeService.fetchByPincode(pincode);

      // Use first result as primary (or let user select if multiple)
      final primary = postOffices.first;

      state = state.copyWith(
        isLoading: false,
        selectedPostOffice: primary,
        allPostOffices: postOffices,
        // Auto-fill common fields
        district: primary.districtName,
        state: primary.stateName,
        taluk: primary.taluk,
      );



    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      Toaster.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearPincodeData() {
    state = state.copyWith(
      selectedPostOffice: null,
      allPostOffices: [],
      district: null,
      state: null,
      taluk: null,
      error: null,
    );
  }
}

class LocationState {
  final bool isLoading;
  final String? error;
  final PincodePostOffice? selectedPostOffice;
  final List<PincodePostOffice> allPostOffices;
  final String? district;
  final String? state;
  final String? taluk;

  LocationState({
    this.isLoading = false,
    this.error,
    this.selectedPostOffice,
    this.allPostOffices = const [],
    this.district,
    this.state,
    this.taluk,
  });

  LocationState copyWith({
    bool? isLoading,
    String? error,
    PincodePostOffice? selectedPostOffice,
    List<PincodePostOffice>? allPostOffices,
    String? district,
    String? state,
    String? taluk,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPostOffice: selectedPostOffice ?? this.selectedPostOffice,
      allPostOffices: allPostOffices ?? this.allPostOffices,
      district: district ?? this.district,
      state: state ?? this.state,
      taluk: taluk ?? this.taluk,
    );
  }
}