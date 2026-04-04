import 'package:arianth/app_color/app_color.dart';
import 'package:flutter/material.dart';

class NavActionItem {
  final String label;
  final IconData? icon;          // 👈 Make nullable
  final Widget? iconWidget;      // 👈 Add this
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? tooltip;
  final bool showLabelOnSmallScreen;
  final bool isPrimary;
  final bool isFloatingCenter;

  const NavActionItem({
    required this.label,
    this.icon,
    this.iconWidget,             // 👈 Add
    required this.color,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.showLabelOnSmallScreen = false,
    this.isPrimary = false,
    this.isFloatingCenter = false,
  });
}

class ERPBottomNavigationBar extends StatelessWidget {
  final List<NavActionItem> actions;
  final Color backgroundColor;

  const ERPBottomNavigationBar({
    Key? key,
    required this.actions,
    this.backgroundColor = AppColor.antiqueFinish, // 👈 Branded background
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double bottomInset = View.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = bottomInset > 0;

    if (isKeyboardVisible) {
      return const SizedBox.shrink();
    }

    // Increased total height to accommodate the floating button with hit-testing
    return SafeArea(
      child: Container(
        height: 90, 
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. The Visual Bar (Navy Container)
            Positioned(
              left: 8,
              right: 8,
              bottom: 4,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Deeper shadow for dark background
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            
            // 2. The Actions Row (SITS ON TOP OF THE BAR BUT SPANS THE FULL HEIGHT)
            Positioned(
              left: 8,
              right: 8,
              bottom: 4,
              top: 0, // Starts from the very top of the 90px container
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: actions.map((action) {
                  if (action.isFloatingCenter) {
                    return _buildCenterFloatingAction(action);
                  }
                  return _buildStandardAction(action);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFloatingAction(NavActionItem config) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            // Position it so the total height fits within the parent's 90px
            // Previously it was top: -25 on a 65px bar. Now it's just relative to this Expanded hit-area.
            bottom: 20, 
            child: GestureDetector(
              onTap: config.enabled ? config.onPressed : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white, // 👈 White circle for contrast
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: config.iconWidget ??
                        Icon(
                          config.icon,
                          color: AppColor.antiqueFinish, // 👈 Branded icon color
                          size: 26,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 👈 White text
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardAction(NavActionItem config) {
    final bool isEnabled = config.enabled && config.onPressed != null;

    return Expanded(
      child: SizedBox(
        height: 65, // Limit height for non-floating items to match the bar height
        child: InkWell(
          onTap: isEnabled ? config.onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                config.iconWidget ??
                    Icon(
                      config.icon,
                      size: 22,
                      color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5), // 👈 White icons
                    ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5), // 👈 White text
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}