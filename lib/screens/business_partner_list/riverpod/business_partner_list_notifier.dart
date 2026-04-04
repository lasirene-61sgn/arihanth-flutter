import 'dart:convert';
import 'package:arianth/screens/business_partner_list/model/business_partner_list_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

class BusinessPartnerListState {
  final bool isLoading;
  final bool isLoaded;
  final bool isSaving;
  final String? error;
  final List<BusinessPartner> businessPartners;
  final List<BusinessPartner> allPartners;
  final List<BusinessPartner> buyers;
  final List<BusinessPartner> craftsmen;
  final int selectedTab; // 0 for Buyers, 1 for Craftsmen
  final int count;
  final String? nextUrl;
  final String? previousUrl;

  const BusinessPartnerListState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isSaving = false,
    this.error,
    this.businessPartners = const [],
    this.allPartners = const [],
    this.buyers = const [],
    this.craftsmen = const [],
    this.selectedTab = 0,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
  });

  BusinessPartnerListState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isSaving,
    String? error,
    List<BusinessPartner>? businessPartners,
    List<BusinessPartner>? allPartners,
    List<BusinessPartner>? buyers,
    List<BusinessPartner>? craftsmen,
    int? selectedTab,
    int? count,
    String? nextUrl,
    String? previousUrl,
  }) {
    return BusinessPartnerListState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      businessPartners: businessPartners ?? this.businessPartners,
      allPartners: allPartners ?? this.allPartners,
      buyers: buyers ?? this.buyers,
      craftsmen: craftsmen ?? this.craftsmen,
      selectedTab: selectedTab ?? this.selectedTab,
      count: count ?? this.count,
      nextUrl: nextUrl, // Use null directly to allow clearing
      previousUrl: previousUrl, // Use null directly to allow clearing
    );
  }
}

class BusinessPartnerListNotifier extends StateNotifier<BusinessPartnerListState> {
  BusinessPartnerListNotifier() : super(const BusinessPartnerListState());
  void resetBusinessPartners() {
    state = state.copyWith(
      businessPartners: state.selectedTab == 0 ? state.buyers : state.craftsmen,
      error: null,
      isLoaded: true,
    );
  }
  Future<void> saveAadhar(String urls,Map<String,dynamic> map, BuildContext context, {
    PlatformFile? aadharAttachment,
    PlatformFile? panAttachment,
    PlatformFile? passbookAttachment,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final url = urls;
      // final response = await Repo().buyersPost(url, map,
      //   aadharAttachment: aadharAttachment,
      //   panAttachment: panAttachment,
      //   passbookAttachment: passbookAttachment,
      // );
      final response = {};
      print("++++ Buyer Save Response: $response");
      if(response["status"] == 1){
        if (response["data"]['id'] != null) {
          // await buyerDetails(response["data"]['id'].toString(), context);
          // await fetchBuyers();
          // if (mounted) {
          //   MessageController.success(context, 'Buyer created successfully');
          //   context.pop();
          // }
          state = state.copyWith(isSaving: false, error: null);
        }
      }else {
        // MessageController.error(context, response["data"]);
        throw Exception('Invalid response from save API');
      }
    } catch (e, stackTrace) {
      print("Stack trace: $stackTrace");
      state = state.copyWith(
        isSaving: false,
        error: "Failed to save buyer: ${e.toString()}",
      );
    }
  }
  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      print("final next ->$relativeUrl");
      state = state.copyWith(businessPartners: []);
      fetchBusinessPartners(url: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      state = state.copyWith(businessPartners: []);
      fetchBusinessPartners(url: relativeUrl);
    }
  }
  /// Fetch the list of business partners from API
  Future<void> fetchBusinessPartners({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);
    print("final ->$url");

    try {
      final response = await ApiClient().get(endpoint: "api/super-admin/business-partners/overview");
      print("++++ Business Partner API Response: $response");

      if (response["status"] == 1 && response["data"] != null) {
        final data = response["data"] as Map<String, dynamic>;

        final innerData = data["data"] as Map<String, dynamic>?;

        if (innerData != null) {
          final List<dynamic> buyersJson = innerData["buyers"] ?? [];
          final List<dynamic> craftsmenJson = innerData["craftsmen"] ?? [];

          final buyers = buyersJson.map((item) => BusinessPartner.fromJson(item)).toList();
          final craftsmen = craftsmenJson.map((item) => BusinessPartner.fromJson(item)).toList();

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            buyers: buyers,
            craftsmen: craftsmen,
            businessPartners: state.selectedTab == 0 ? buyers : craftsmen,
            allPartners: buyers + craftsmen,
            count: buyers.length + craftsmen.length,
          );
        } else {
          throw Exception('Data not found in response');
        }
      } else {
        throw Exception('Invalid response format or status not 1');
      }
    } catch (e, stackTrace) {
      print("Business Partner fetch error: ${e.toString()}");
      print("Stack trace: $stackTrace");

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: "Failed to load data: ${e.toString()}",
      );
    }
  }

  void changeTab(int index) {
    state = state.copyWith(
      selectedTab: index,
      businessPartners: index == 0 ? state.buyers : state.craftsmen,
    );
  }

  void filterBusinessPartners(String selectedField, String query) {
    final searchValue = query.toLowerCase();
    final sourceList = state.selectedTab == 0 ? state.buyers : state.craftsmen;

    if (searchValue.isEmpty) {
      state = state.copyWith(businessPartners: sourceList);
      return;
    }

    final filteredList = sourceList.where((partner) {
      if (selectedField == 'All') {
        return (partner.bpCode ?? '').toLowerCase().contains(searchValue) ||
            (partner.businessName ?? '').toLowerCase().contains(searchValue) ||
            (partner.name ?? '').toLowerCase().contains(searchValue) ||
            (partner.mobile ?? '').toLowerCase().contains(searchValue) ||
            (partner.businessEmail ?? '').toLowerCase().contains(searchValue);
      }

      switch (selectedField) {
        case 'BP Code':
          return (partner.bpCode ?? '').toLowerCase().contains(searchValue);
        case 'Role':
          return (partner.role ?? '').toLowerCase().contains(searchValue);
        case 'Business Name':
          return (partner.businessName ?? '').toLowerCase().contains(searchValue);
        case 'Customer Name':
          return (partner.name ?? '').toLowerCase().contains(searchValue);
        case 'Mobile':
          return (partner.mobile ?? '').toLowerCase().contains(searchValue);
        case 'Email':
          return (partner.businessEmail ?? '').toLowerCase().contains(searchValue);
        default:
          return true;
      }
    }).toList();

    state = state.copyWith(businessPartners: filteredList);
  }





  /// ✅ Updated: Sort partners (respects current filter)
  void sortBusinessPartners(String sortKey, {bool ascending = true}) {
    final currentList = List<BusinessPartner>.from(state.businessPartners);

    int compare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    }

    currentList.sort((a, b) {
      int result = 0;

      switch (sortKey) {
        case 'BP Code':
          result = compare(a.bpCode, b.bpCode);
          break;
        case 'Mobile':
          result = compare(int.tryParse(a.mobile ?? ''), int.tryParse(b.mobile ?? ''));
          break;
        case 'Business Name':
          result = compare(a.businessName, b.businessName);
          break;
        case 'Customer Name':
          result = compare(a.name, b.name);
          break;
        case 'Role':
          result = compare(a.role, b.role);
          break;
        case 'Email':
          result = compare(a.businessEmail, b.businessEmail);
          break;

      }

      return ascending ? result : -result;
    });

    state = state.copyWith(businessPartners: currentList);
  }

}

final businessPartnerListProvider =
StateNotifierProvider<BusinessPartnerListNotifier, BusinessPartnerListState>(
      (ref) => BusinessPartnerListNotifier(),
);