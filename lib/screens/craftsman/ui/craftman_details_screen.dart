import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/reusable_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/screens/craftsman/model/craftsman_model.dart';
import 'package:arianth/screens/craftsman/riverpod/craftsman_notifier.dart';

class CraftsmanDetailScreen extends ConsumerStatefulWidget {
  final String? id;
  const CraftsmanDetailScreen({super.key, this.id});

  @override
  ConsumerState<CraftsmanDetailScreen> createState() => _CraftsmanDetailScreenState();
}

class _CraftsmanDetailScreenState extends ConsumerState<CraftsmanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Prioritize ID from constructor, fallback to Get.arguments
    final String? effectiveId = widget.id ?? Get.arguments?.toString();

    if (effectiveId != null) {
      Future.microtask(() =>
          ref.read(craftsmanListProvider.notifier).fetchCraftsmanDetail(int.parse(effectiveId))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(craftsmanListProvider);
    final craftsman = state.selectedCraftsman;

    // 1. Loading State
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    // 2. Error/Empty State
    if (craftsman == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColor.textHint),
              const SizedBox(height: 16),
              Text(state.error ?? "No Craftsman Data Found"),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Get.back(), child: const Text("Go Back")),
            ],
          ),
        ),
      );
    }

    // 3. Main Detailed View using your Reusable Component
    return ReusableDetailView(
      title: 'Craftsman Profile Details',
      onBackPressed: () => Get.back(),
      sections: _buildSections(craftsman),
    );
  }

  List<DetailSection> _buildSections(Craftsman craftsman) {
    return [
      // Section: Personal & Professional Info
      DetailSection(
        title: 'Basic Information',
        items: [
          DetailItem(label: 'Craftsman Code', value: craftsman.craftmanCode, copyable: true),
          DetailItem(label: 'Full Name', value: craftsman.name, copyable: true),
          DetailItem(label: 'Mobile', value: craftsman.mobile, copyable: true),
          DetailItem(label: 'Email', value: craftsman.email),
          DetailItem(label: 'KYC Status', value: craftsman.kycStatus),
          DetailItem(label: 'Status', value: (craftsman.kycStatus == 1) ? "Active" : "Inactive"),
        ],
      ),

      // Section: Address Info
      DetailSection(
        title: 'Location Details',
        items: [
          DetailItem(label: 'City', value: craftsman.city),
          DetailItem(label: 'State', value: craftsman.state),
          DetailItem(label: 'Pincode', value: craftsman.pincode),
          DetailItem(label: 'Country', value: craftsman.city),
        ],
      ),

      // Section: Identity Documents
      DetailSection(
        title: 'KYC Details',
        items: [
          DetailItem(
            label: 'Aadhar Number',
            value: craftsman.aadharNo,
            imageUrl: craftsman.aadharAttachmentUrl, // Ensure this field exists in your model
            imageSize: 60,
          ),
          DetailItem(
            label: 'Profile Picture',
            value: craftsman.panAttachmentUrl != null ? "Available" : "Not Provided",
            imageUrl: craftsman.panAttachmentUrl,
            imageSize: 60,
          ),
        ],
      ),

    ];
  }
}