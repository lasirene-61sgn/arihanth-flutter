import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: AppColor.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: AppColor.textHint),
            const SizedBox(height: 16),
            const Text(
              "No new notifications",
              style: TextStyle(color: AppColor.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
