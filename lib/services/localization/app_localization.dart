import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'translations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final prefs = SharedPreferencesHelper();
    final savedCode = prefs.getString('app_locale');
    if (savedCode != null && AppTranslations.translations.containsKey(savedCode)) {
      state = Locale(savedCode);
    }
  }

  void setLocale(Locale locale) {
    if (AppTranslations.translations.containsKey(locale.languageCode)) {
      state = locale;
      SharedPreferencesHelper().setString('app_locale', locale.languageCode);
    }
  }

  String translate(String key) {
    return AppTranslations.translate(key, state.languageCode);
  }
}

extension LocalizationExtension on WidgetRef {
  String tr(String key) {
    return this.read(localeProvider.notifier).translate(key);
  }
  
  String watchTr(String key) {
    final locale = this.watch(localeProvider);
    return AppTranslations.translate(key, locale.languageCode);
  }
}
