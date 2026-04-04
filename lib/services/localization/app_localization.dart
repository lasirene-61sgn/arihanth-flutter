import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'translations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(Locale locale) {
    if (AppTranslations.translations.containsKey(locale.languageCode)) {
      state = locale;
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
