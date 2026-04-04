import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/update_service/update_service.dart';

class SplashScreen extends StatefulWidget {
  final String targetRoute;

  const SplashScreen({Key? key, required this.targetRoute}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 1. Logo Animation: Elegant slow fade and subtle scale up
    _logoController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800)
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // 2. Text Animation: Elegant fade and slight slide up
    _textController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start Sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Start logo appearance
    await _logoController.forward();
    
    // Once logo is settled, start text appearance
    await _textController.forward();

    // Check for in-app updates (Android Only)
    await UpdateService().checkForUpdate();

    // Wait to let the user admire the luxurious splash
    await Future.delayed(const Duration(milliseconds: 1500));

    // Navigate to the target route
    Get.offAllNamed(widget.targetRoute);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  // margin: const EdgeInsets.all(40),
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/image/splash_screen_logo_without_bg.png'),),

                    // shape: BoxShape.circle,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.1),
                    //     blurRadius: 20,
                    //     spreadRadius: 2,
                    //   ),
                    // ],
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 40),
            
            // Animated Text
            // FadeTransition(
            //   opacity: _textFade,
            //   child: SlideTransition(
            //     position: _textSlide,
            //     child: Column(
            //       children: [
            //         const Text(
            //           'ARIHANTH',
            //           textAlign: TextAlign.center,
            //           style: TextStyle(
            //             fontSize: 28,
            //             fontFamily: 'Serif', // Using a serif font for a premium look
            //             fontWeight: FontWeight.w600,
            //             letterSpacing: 4.0,
            //             color: Color(0xFFFFD700), // Gold Color
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         const Text(
            //           'JEWELLERS PRIVATE LIMITED',
            //           textAlign: TextAlign.center,
            //           style: TextStyle(
            //             fontSize: 12,
            //             fontWeight: FontWeight.w400,
            //             letterSpacing: 3.0,
            //             color: AppColor.textSecondary,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
