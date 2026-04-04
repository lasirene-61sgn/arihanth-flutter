import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_color/app_color.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderNo;
  final String orderType; // 'Work Order' or 'Repair Order'
  final VoidCallback onBack;

  const OrderSuccessScreen({
    super.key,
    required this.orderNo,
    required this.orderType,
    required this.onBack,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Success Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColor.success,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(60, 60),
                          painter: CheckPainter(_checkAnimation.value),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '${widget.orderType} Created!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order No: ${widget.orderNo}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Back to List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckPainter extends CustomPainter {
  final double progress;
  CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
