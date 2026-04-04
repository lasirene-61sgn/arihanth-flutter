import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSelector {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Select Language",
              style: TextStyle(
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _languageTile(context, ref, "English", "en"),
                  _languageTile(context, ref, "Hindi (हिन्दी)", "hi"),
                  _languageTile(context, ref, "Tamil (தமிழ்)", "ta"),
                  _languageTile(context, ref, "Bengali (বাংলা)", "bn"),
                  _languageTile(context, ref, "Marathi (मराठी)", "mr"),
                  _languageTile(context, ref, "Telugu (తెలుగు)", "te"),
                  _languageTile(context, ref, "Gujarati (ગુજરાતી)", "gu"),
                  _languageTile(context, ref, "Urdu (اردو)", "ur"),
                  _languageTile(context, ref, "Kannada (ಕನ್ನಡ)", "kn"),
                  _languageTile(context, ref, "Odia (ଓଡ଼ିଆ)", "or"),
                  _languageTile(context, ref, "Malayalam (മലയാളം)", "ml"),
                  _languageTile(context, ref, "Punjabi (ਪੰਜਾਬੀ)", "pa"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _languageTile(BuildContext context, WidgetRef ref, String title, String code) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale.languageCode == code;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColor.primary : AppColor.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColor.primary) : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}
