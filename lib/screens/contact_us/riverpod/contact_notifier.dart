import 'package:arianth/screens/contact_us/model/contact_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ContactState {
  final bool isLoading;
  final String? error;
  final CompanyContacts? contacts;

  const ContactState({
    this.isLoading = false,
    this.error,
    this.contacts,
  });

  ContactState copyWith({
    bool? isLoading,
    String? error,
    CompanyContacts? contacts,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      contacts: contacts ?? this.contacts,
    );
  }
}

class ContactNotifier extends StateNotifier<ContactState> {
  ContactNotifier() : super(const ContactState());

  Future<void> fetchContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient().get(endpoint: 'api/company-contacts');

      print("contact $response");
      final data = response['data'];
      if (data != null && data['success'] == true) {
        final contacts = CompanyContacts.fromJson(data['data'] as Map<String, dynamic>);
        state = state.copyWith(isLoading: false, contacts: contacts);
      } else {
        final msg = data?['message']?.toString() ?? 'Failed to load contact info';
        state = state.copyWith(isLoading: false, error: msg);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final contactProvider = StateNotifierProvider<ContactNotifier, ContactState>(
  (ref) => ContactNotifier(),
);
