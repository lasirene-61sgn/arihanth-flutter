package com.ajpl.arianth

import android.view.WindowManager.LayoutParams
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Uncomment the next line to enable screenshot/recording protection in Production
        // if (!BuildConfig.DEBUG) {
            window.addFlags(LayoutParams.FLAG_SECURE)
        // }
        super.configureFlutterEngine(flutterEngine)
    }
}
