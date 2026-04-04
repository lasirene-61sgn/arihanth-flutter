import 'package:android_intent_plus/android_intent.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';

class NetworkOverlay extends StatefulWidget {
  const NetworkOverlay({super.key});

  @override
  State<NetworkOverlay> createState() => _NetworkOverlayState();
}

class _NetworkOverlayState extends State<NetworkOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Animates back and forth

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 1. Real-time Pulse Animation ---
              ScaleTransition(
                scale: _animation,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1), //
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: AppColor.background, //
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // --- 2. Text Content ---
              const Text(
                "Your internet appears to be offline",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {


                  Toaster.showError("Please enable internet");
                  const intent = AndroidIntent(
                    action: 'android.settings.DATA_ROAMING_SETTINGS',
                  );
                  await intent.launch();

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Clean white background
                  foregroundColor: Colors.black, // Ripple effect color
                  elevation: 0, // Flat design
                  minimumSize: const Size(180, 50),
                  side: const BorderSide(color: Colors.black12, width: 1), // Thin subtle border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Enable Network",
                  style: TextStyle(
                    color: Colors.black, // Black text as requested
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}