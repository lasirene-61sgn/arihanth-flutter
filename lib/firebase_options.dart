import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1qU5l5aeEd1sn7hHlU4A-qYPeQFeKECA', // Found in google-services.json -> current_key
    appId: '1:601146486892:android:38f9cf3da2b85f6b1aa849',   // Found in google-services.json -> mobilesdk_app_id
    messagingSenderId: '601146486892', // Found in google-services.json -> project_number
    projectId: 'arihanth-1938c',       // Found in google-services.json -> project_id
    storageBucket: 'arihanth-1938c.firebasestorage.app',
  );
}