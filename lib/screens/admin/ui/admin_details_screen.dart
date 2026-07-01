import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/admin/model/admin_model.dart';
import 'package:arianth/screens/admin/riverpod/admin_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/reusable_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class AdminDetailsScreen extends ConsumerStatefulWidget {
  final String? adminId;

  const AdminDetailsScreen({
    super.key,
    required this.adminId,
  });

  @override
  ConsumerState<AdminDetailsScreen> createState() => _AdminDetailsScreenState();
}

class _AdminDetailsScreenState extends ConsumerState<AdminDetailsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.adminId != null && widget.adminId != "null") {
      Future.microtask(() => ref.read(adminProvider.notifier).adminDetails(widget.adminId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final admin = state.adminDetail;

    return ReusableDetailView(
      title: "Admin Details",
      isLoading: state.isLoading,
      onBackPressed: () => Get.back(),
      action: admin != null ? IconButton(
        icon: const Icon(Icons.edit, color: AppColor.white),
        onPressed: () {
          Get.toNamed(AppRoutes.addAdmin, arguments: admin.id.toString());
        },
      ) : null,
      sections: admin != null ? _buildSections(admin) : [],
    );
  }

  List<DetailSection> _buildSections(Admin a) {
    return [
      DetailSection(
        title: "Basic Information",
        items: [
          DetailItem(label: "Full Name", value: a.fullName),
          DetailItem(label: "Designation", value: a.category),
          DetailItem(label: "User Code", value: a.bpCode, copyable: true),
          // DetailItem(label: "BP Code", value: a.bpCode, copyable: true),
          DetailItem(label: "Email ID", value: a.emailId, copyable: true),
          DetailItem(label: "Mobile No", value: a.mobileNo, copyable: true),
          DetailItem(label: "Date of Birth", value: a.dob),
          DetailItem(label: "Status", value: a.status == 1 ? "Active" : "Inactive"),
          if (a.profilePicture != null && a.profilePicture!.isNotEmpty)
            DetailItem(
              label: "Profile Picture",
              imageUrl: a.profilePicture,
              imageSize: 120,
            ),
        ],
      ),
      DetailSection(
        title: "Location Details",
        items: [
          DetailItem(label: "City", value: a.city),
          DetailItem(label: "State", value: a.state),
          DetailItem(label: "Country", value: a.country),
          DetailItem(label: "Pincode", value: a.pincode),
        ],
      ),
      DetailSection(
        title: "KYC Details",
        items: [
          DetailItem(label: "Aadhar Number", value: a.aadharNumber, copyable: true),
          if (a.aadharPhoto != null && a.aadharPhoto!.isNotEmpty)
            DetailItem(
              label: "Aadhar Photo",
              imageUrl: a.aadharPhoto,
              imageSize: 160,
            ),
        ],
      ),
      DetailSection(
        title: "Permissions",
        items: [
          DetailItem(
            label: "Assigned Permissions",
            value: a.permissions.isEmpty ? "No permissions assigned" : a.permissions.join(", "),
          ),
        ],
      ),

    ];
  }
}
