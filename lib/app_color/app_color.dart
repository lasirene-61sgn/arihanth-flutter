import 'package:flutter/material.dart';

class AppColor {
  // --- Basic Colors ---
  static const Color white = Color(0xFFfdf7f1);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color bronze = Color(0xFF8D6E63);
  static const Color bloodRed = Color(0xFF7B1113);
  // --- Core Brand Colors ---
  static const Color jetBlack = Color(0xFF2D3142);        // Dark Grey/Black
  static const Color coralGlow = Color(0xFFEF8354);       // Accent Orange
  // static const Color coralGlow = bloodRed;       // Accent Orange
  static const Color blueSlate = Color(0xFF4F5D75);       // Muted Blue/Grey
  static const Color silver = Color(0xFFBFC0C0);          // Silver/Light Grey
  // static const Color antiqueFinish = Color(0xFFD4af37);   // Dark Red from Splash
  static const Color antiqueFinish = Color(0xFFA57C52);   // Dark Red from Splash
  static const Color splashDeepMaroon = Color(0xFF4A0000); // Deep Maroon from Splash
  static const Color sidebarColor = white; // Deep Maroon from Splash
  // --- functional Colors (Light Theme) ---
  static const Color primary = antiqueFinish;
  static const Color secondary = blueSlate;
  static const Color accent = antiqueFinish;
  
  static const Color background = white;
  static const Color surface = Color(0xFFF9FAFB);         // Very light grey for cards
  static const Color border = Color(0xFFE5E7EB);          // Light grey border
  static const Color divider = Color(0xFFF3F4F6);

  // --- Typography ---
  static const Color textPrimary = Color(0xFF111827);     // Dark for readability
  static const Color textSecondary = Color(0xFF6B7280);   // Muted grey
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textWhite = white;

  // --- Feedback ---
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color teal = Color(0xFF009688);
  static const Color indigo = Color(0xFF3F51B5);

  // --- Legacy Aliases (pointing to new functional colors) ---
  static const Color darkNavy = jetBlack;                 // For elements that must stay dark
  static const Color deepMutedPurple = blueSlate;
  static const Color coolLavender = silver;
  static const Color softOrange = coralGlow;

  // --- Specific UI Elements ---
  static const Color cardShadow = Color(0x1A000000);      // Lighter shadow for light theme
  static const Color appBarBackground = antiqueFinish;
  static const Color tableHeader = Color(0xFFF3F4F6);
}