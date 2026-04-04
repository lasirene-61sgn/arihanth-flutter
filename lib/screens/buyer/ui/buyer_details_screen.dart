import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/reusable_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/screens/buyer/model/buyer_model.dart';
import 'package:arianth/screens/buyer/riverpod/buyer_notifier.dart';

class BuyerDetailScreen extends ConsumerStatefulWidget {
  final String? id;
  const BuyerDetailScreen({super.key, this.id});

  @override
  ConsumerState<BuyerDetailScreen> createState() => _BuyerDetailScreenState();
}

class _BuyerDetailScreenState extends ConsumerState<BuyerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Prioritize ID from constructor, fallback to Get.arguments
    final String? effectiveId = widget.id ?? Get.arguments?.toString();

    if (effectiveId != null) {
      Future.microtask(() =>
          ref.read(buyerListProvider.notifier).fetchBuyerDetail(int.parse(effectiveId))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerListProvider);
    final buyer = state.selectedBuyer;

    // 1. Loading State (Clean screen as requested)
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    // 2. Error/Empty State
    if (buyer == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColor.textHint),
              const SizedBox(height: 16),
              Text(state.error ?? "No Buyer Data Found"),
              TextButton(onPressed: () => Get.back(), child: const Text("Go Back")),
            ],
          ),
        ),
      );
    }

    // 3. Main Detailed View using your Reusable Component
    return ReusableDetailView(
      title: 'Buyer Profile Details',
      onBackPressed: () => Get.back(),
      sections: _buildSections(buyer),
    );
  }

  List<DetailSection> _buildSections(Buyer buyer) {
    return [
      // Section: Business Info
      DetailSection(
        title: 'Business Information',
        items: [
          DetailItem(label: 'BP Code', value: buyer.bpCode, copyable: true),
          DetailItem(label: 'Business Name', value: buyer.businessName, copyable: true),
          DetailItem(label: 'Customer Name', value: buyer.name),
          DetailItem(label: 'Mobile', value: buyer.mobile, copyable: true),
          DetailItem(label: 'Email', value: buyer.email),
          DetailItem(label: 'Business Email', value: buyer.businessEmail),
          DetailItem(label: 'KYC Status', value: buyer.kycStatus),
          DetailItem(label: 'Account Status', value: buyer.isFrozen == 1 ? "Frozen" : "Active"),
        ],
      ),

      // Section: Address Info
      DetailSection(
        title: 'Address Details',
        items: [
          DetailItem(label: 'Area', value: buyer.area),
          DetailItem(label: 'City', value: buyer.city),
          DetailItem(label: 'State', value: buyer.state),
          DetailItem(label: 'Pincode', value: buyer.pincode),
        ],
      ),

      // Section: KYC Details (Consolidated)
      DetailSection(
        title: 'KYC Details',
        items: [
          // Primary IDs
          DetailItem(
            label: 'GST Number',
            value: buyer.gstNo,
            imageUrl: buyer.gstAttachmentUrl,
            imageSize: 60,
          ),
          DetailItem(
            label: 'PAN Number',
            value: buyer.panNo,
            imageUrl: buyer.panAttachmentUrl,
            imageSize: 60,
          ),
          DetailItem(
            label: 'Primary Aadhar',
            value: buyer.aadharNo,
            imageUrl: buyer.aadharAttachmentUrl,
            imageSize: 60,
          ),

          // Additional Records
          ...buyer.aadharDetails.map((a) => DetailItem(
            label: a.aadharName ?? 'Aadhar Card',
            value: a.aadharNumber,
            imageUrl: a.aadharImageUrl,
            imageSize: 50,
          )),
          ...buyer.panDetails.map((p) => DetailItem(
            label: 'PAN Card',
            value: p.panNumber,
            imageUrl: p.panImageUrl,
            imageSize: 50,
          )),
        ],
      ),

      // Section: Permissions
      DetailSection(
        title: 'Access Permissions',
        items: [
          DetailItem(
            label: 'Permissions List',
            value: buyer.permissions.isEmpty ? "No permissions assigned" : buyer.permissions.join(", "),
          ),
        ],
      ),
    ];
  }
}