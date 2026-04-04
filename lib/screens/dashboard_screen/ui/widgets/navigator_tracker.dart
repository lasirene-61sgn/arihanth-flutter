import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
/// Custom NavigatorObserver to track screen visits for dynamic quick links
class ScreenTrackingObserver extends NavigatorObserver {

  // Map of routes to their display names
  final Map<String, String> _routeNames = {
    '/dashboard': 'Dashboard',
    '/workOrders': 'Work Orders',
    '/users': 'Users',
    '/businessPartners': 'Business Partners',
    '/buyers': 'Buyers',
    '/settings': 'Craftsman',
    '/craftsman': 'Craftsman Master',
    '/admin': 'Admin',
    '/keyUsers': 'Key Users',
    '/finance': 'Finance',
    '/products': 'Products',
    '/designs': 'Designs',
    '/myCatalogue': 'My Catalogue',
    '/purchaseOrder': 'Purchase Orders',
    '/kycPending': 'KYC Pending',
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route<dynamic> route) {
    if (route.settings.name == null) return;

    final routeName = route.settings.name!;

    // Skip tracking for login and auth screens
    if (routeName.contains('/login') ||
        routeName.contains('/otp') ||
        routeName.contains('/forgetPassword')) {
      return;
    }

    // Skip tracking for detail/add/edit sub-routes
    if (routeName.contains('/add') ||
        routeName.contains('/view') ||
        routeName.contains('/View') ||
        routeName.contains('/Edit')) {
      return;
    }

    // Get display name for route
    String? displayName = _routeNames[routeName];

    if (displayName != null) {
      // Get icon name
      String iconName = NavigationTracker.getIconNameForRoute(routeName);

      // Track the visit
      NavigationTracker.trackScreenVisit(
        screenName: displayName,
        routePath: routeName,
        iconName: iconName,
      );
    }
  }
}

/// Service to track recently visited screens for dynamic quick links
class NavigationTracker {
  static const String _recentScreensKey = 'recent_screens';
  static const int _maxRecentScreens = 5;

  /// Track a screen visit
  static Future<void> trackScreenVisit({
    required String screenName,
    required String routePath,
    required String iconName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing recent screens
      List<Map<String, dynamic>> recentScreens = await getRecentScreens();

      // Create new screen entry
      Map<String, dynamic> newScreen = {
        'screenName': screenName,
        'routePath': routePath,
        'iconName': iconName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Remove if already exists (to update position)
      recentScreens.removeWhere((screen) => screen['routePath'] == routePath);

      // Add to beginning
      recentScreens.insert(0, newScreen);

      // Keep only last 5
      if (recentScreens.length > _maxRecentScreens) {
        recentScreens = recentScreens.sublist(0, _maxRecentScreens);
      }

      // Save back to preferences
      final jsonString = jsonEncode(recentScreens);
      await prefs.setString(_recentScreensKey, jsonString);
    } catch (e) {
      // Silent fail - don't crash the app
      print('Error tracking screen visit: $e');
    }
  }

  /// Get recent screens
  static Future<List<Map<String, dynamic>>> getRecentScreens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentScreensKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error getting recent screens: $e');
      return [];
    }
  }

  /// Clear all recent screens
  static Future<void> clearRecentScreens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentScreensKey);
    } catch (e) {
      print('Error clearing recent screens: $e');
    }
  }

  /// Get icon data from icon name
  static String getIconNameForRoute(String routePath) {
    final iconMap = {
      '/users': 'person_add_alt_1',
      '/businessPartners': 'business',
      '/buyers': 'shopping_cart',
      '/settings': 'build',
      '/craftsman': 'handyman',
      '/admin': 'admin_panel_settings',
      '/keyUsers': 'key',
      '/finance': 'attach_money',
      '/products': 'inventory',
      '/designs': 'design_services',
      '/myCatalogue': 'menu_book',
      '/purchaseOrder': 'description',
      '/workOrders': 'assignment',
      '/kycPending': 'warning',
    };

    return iconMap[routePath] ?? 'star';
  }
}