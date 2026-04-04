import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? name, email, role, userCode, bpCode, userId, mobile, businessName, image, aadharNo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = SharedPreferencesHelper();
    await prefs.init();
    setState(() {
      name = prefs.getString("name") ?? '';
      email = prefs.getString("email") ?? '';
      role = prefs.getString("role") ?? '';
      userCode = prefs.getString("user_code") ?? '';
      bpCode = prefs.getString("userBpCode") ?? '';
      userId = prefs.getString("userId") ?? '';
      mobile = prefs.getString("mobile") ?? '';
      businessName = prefs.getString("businessName") ?? '';
      image = prefs.getString("image") ?? '';
      aadharNo = prefs.getString("aadharNo") ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 0,
        title: Text(
          ref.watchTr('profile'),
          style: const TextStyle(color: AppColor.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 25),
              _buildInfoList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25,vertical: 10),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [
        //     AppColor.primary.withValues(alpha: 0.2),
        //     AppColor.primary.withValues(alpha: 0.1),
        //   ],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        color:AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColor.primary.withValues(alpha: 0.1),
            backgroundImage: (image != null && image!.isNotEmpty)
                ? NetworkImage(image!)
                : null,
            child: (image == null || image!.isEmpty)
                ? Text(
              (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : "U",
              style: const TextStyle(
                color: AppColor.primary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            name ?? "User",
            style: const TextStyle(
              color: AppColor.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email ?? "",
            style: const TextStyle(
              color: AppColor.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role?.toUpperCase() ?? "",
              style: const TextStyle(
                color: AppColor.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary),
      ),
      child: Column(
        children: [
          _buildInfoTile(Icons.person_outline, ref.watchTr('name'), name),
          _buildDivider(),
          _buildInfoTile(Icons.email_outlined, ref.watchTr('email'), email),
          _buildDivider(),
          if (mobile != null && mobile!.isNotEmpty) ...[
            _buildInfoTile(Icons.phone_outlined, ref.watchTr('mobile'), mobile),
            _buildDivider(),
          ],
          if (businessName != null && businessName!.isNotEmpty) ...[
            _buildInfoTile(Icons.business_center_outlined, ref.watchTr('business_name'), businessName),
            _buildDivider(),
          ],
          if (aadharNo != null && aadharNo!.isNotEmpty) ...[
            _buildInfoTile(Icons.badge_outlined, ref.watchTr('aadhar_no'), aadharNo),
            _buildDivider(),
          ],
         if(role == "user" || role == "key_user") _buildInfoTile(Icons.badge_outlined, ref.watchTr('user_code'), userCode?.isNotEmpty == true ? userCode : bpCode),
          _buildDivider(),
          _buildInfoTile(Icons.workspace_premium_outlined, ref.watchTr('role'), role),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: AppColor.primary, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: AppColor.black, fontSize: 13),
      ),
      subtitle: Text(
        value ?? "N/A",
        style: const TextStyle(color: AppColor.primary, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColor.coolLavender.withValues(alpha: 0.05),
      indent: 20,
      endIndent: 20,
    );
  }
}
