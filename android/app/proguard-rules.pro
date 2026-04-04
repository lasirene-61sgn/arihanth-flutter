# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase & GMS (Since you are using Firebase BOM 34.10.0)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# PDF & Internet File (To support your PdfThumbnail component)
-keep class com.shockwave.** { *; }

# ML Kit (Fixing R8 build failure for missing optional language modules)
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**

# Play Core (Referenced by Flutter deferred components, but often not included)
-dontwarn com.google.android.play.core.**