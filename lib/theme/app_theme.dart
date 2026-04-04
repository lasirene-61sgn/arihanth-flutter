import 'package:flutter/material.dart';
import '../app_color/app_color.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColor.primary,
      scaffoldBackgroundColor: AppColor.background,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.primary,
        primary: AppColor.primary,
        secondary: AppColor.secondary,
        surface: AppColor.surface,
        onSurface: AppColor.textPrimary,
        onPrimary: AppColor.textWhite,
        error: AppColor.error,
        brightness: Brightness.light,
      ),

      // 1. Unified AppBar (White/Light)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.appBarBackground,
        foregroundColor: AppColor.textWhite, // 👈 White for dark red background
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: AppColor.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColor.textWhite, // 👈 White text
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColor.textWhite), // 👈 White icons
      ),

      // 2. Structured Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColor.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColor.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: AppColor.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.2),
        bodyMedium: TextStyle(color: AppColor.textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: AppColor.primary, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: AppColor.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // 3. Dense & Secure Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColor.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColor.primary),
      ),

      // 4. Premium Cards
      cardTheme: CardThemeData(
        color: AppColor.white,
        elevation: 1,
        shadowColor: AppColor.cardShadow,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColor.divider, width: 0.8),
        ),
      ),

      // 5. Professional List Tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.transparent,
        titleTextStyle: const TextStyle(color: AppColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        subtitleTextStyle: const TextStyle(color: AppColor.textSecondary, fontSize: 13),
        iconColor: AppColor.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 6. Data Table Styling
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(color: AppColor.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
        dataTextStyle: const TextStyle(color: AppColor.textPrimary, fontSize: 13),
        headingRowColor: WidgetStateProperty.all(AppColor.tableHeader),
        dividerThickness: 0.5,
      ),

      // 7. Refined Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.textWhite,
          side: const BorderSide(color: AppColor.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      // 8. Navigation & Interaction
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColor.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColor.primary,
        unselectedLabelColor: AppColor.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(AppColor.primary.withOpacity(0.05)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColor.antiqueFinish, // 👈 Branded background
        selectedItemColor: AppColor.textWhite,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColor.divider,
        thickness: 0.8,
        space: 24,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
