import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  AppUpdateInfo? _updateInfo;
  GlobalKey<ScaffoldState>? _scaffoldKey;

  void setScaffoldKey(GlobalKey<ScaffoldState> key) {
    _scaffoldKey = key;
  }

  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) {
      debugPrint("In-app updates are only supported on Android.");
      return;
    }

    try {
      _updateInfo = await InAppUpdate.checkForUpdate();

      if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
        if (_updateInfo?.immediateUpdateAllowed == true && (_updateInfo?.updatePriority ?? 0) >= 4) {
          _performImmediateUpdate();
        } else if (_updateInfo?.flexibleUpdateAllowed == true) {
          _startFlexibleUpdate();
        }
      }
    } on PlatformException catch (e) {
      if (e.code == 'TASK_FAILURE' && e.message?.contains('-10') == true) {
        debugPrint("In-app update: App not owned by user (common in debug/side-loaded builds). Skipping update check.");
      } else {
        debugPrint("Platform error checking for update: ${e.code} - ${e.message}");
      }
    } catch (e) {
      debugPrint("General error checking for update: $e");
    }
  }

  /// Starts a flexible update (downloads in background).
  Future<void> _startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      
      // Once downloaded, we need to prompt the user to complete the update.
      _showUpdateDownloadedSnackbar();
      
    } catch (e) {
      debugPrint("Error starting flexible update: $e");
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint("Error performing immediate update: $e");
    }
  }

  void _showUpdateDownloadedSnackbar() {
    Fluttertoast.showToast(
      msg: "Update downloaded. Restarting to apply...",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Future.delayed(const Duration(seconds: 3), () {
      InAppUpdate.completeFlexibleUpdate().then((_) {
        debugPrint("Update completed successfully.");
      }).catchError((e) {
        debugPrint("Error completing update: $e");
      });
    });
  }
}
