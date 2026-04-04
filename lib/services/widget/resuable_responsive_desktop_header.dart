import 'package:flutter/material.dart';

/// Action Button Configuration
class ActionButtonConfig {
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? tooltip;
  final bool showLabelOnSmallScreen;

  const ActionButtonConfig({
    required this.label,
    this.icon,
    this.iconWidget,
    required this.color,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.showLabelOnSmallScreen = false,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');
}

/// Reusable Desktop Header Widget
class ResponsiveDesktopHeader extends StatelessWidget {
  final String title;
  final List<ActionButtonConfig> actions;
  final double breakpoint;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showBorder;
  final bool showShadow;
  final double? width;

  const ResponsiveDesktopHeader({
    Key? key,
    required this.title,
    required this.actions,
    this.breakpoint = 600,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 8,
    this.showBorder = true,
    this.showShadow = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileView = screenWidth < breakpoint;
    // Compact mode for actions (used for screens < 900)
    final isCompactActions = screenWidth < 900;

    return Container(
      width: width,
      padding: padding ??
          (isMobileView
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              :  const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      child: isMobileView
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context, isCompactActions),
    );
  }

  // Layout for screens < breakpoint (Mobile/Tablet View)
  Widget _buildMobileLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        // Title takes the remaining space
        // Expanded(
        //   child: Text(
        //     title,
        //     style: titleStyle ?? HeaderPresets.titleStyle.copyWith(fontSize: 18),
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ),
        // Actions container for mobile/compact view (icons only, forced scrollable)
        // Wrapped in Expanded to ensure it takes available space and allows scrolling
        Expanded(
          flex: 2, // Give actions more space than default 1
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildActionsContainer(
              context,
              _buildMobileStyleActions(context),
              showContainer: false,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }

  // Layout for screens >= breakpoint (Desktop View)
  Widget _buildDesktopLayout(BuildContext context, bool isCompactActions) {
    // Determine which action builder to use
    final Widget actionsWidget = isCompactActions
        ? _buildMobileStyleActions(context)
        : _buildFullActions(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Flexible(
          flex: isCompactActions ? 2 : 1, // Adjust flex based on size
          child: _buildActionsContainer(context, actionsWidget, showContainer: true),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }

  // Helper function to build the actions section container
  Widget _buildActionsContainer(
      BuildContext context,
      Widget actionsWidget,
      {required bool showContainer}
      ) {
    if (!showContainer) {
      return actionsWidget;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: Colors.grey.withOpacity(0.3))
            : null,
        boxShadow: showShadow
            ? [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: actionsWidget,
    );
  }

  // Full actions layout (Desktop > 900px) - Shows labels always
  Widget _buildFullActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          final isLast = action == actions.last;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: _ActionButton(
              config: action,
              showLabel: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  // Mobile/Compact style actions - Icons only, labels are NEVER shown
  Widget _buildMobileStyleActions(BuildContext context) {
    // SingleChildScrollView is what enables the horizontal scroll
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          final isLast = action == actions.last;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: _ActionButton(
              config: action,
              showLabel: false, // Always false for this style
              compact: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Internal Action Button Widget
class _ActionButton extends StatefulWidget {
  final ActionButtonConfig config;
  final bool showLabel;
  final bool compact;

  const _ActionButton({
    required this.config,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final isEnabled = config.enabled && config.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: config.tooltip ?? config.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? config.color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled
                  ? (_isHovered ? config.color : config.color.withOpacity(0.3))
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? config.onPressed : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: widget.compact
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (config.iconWidget != null)
                      config.iconWidget!
                    else if (config.icon != null)
                      Icon(
                        config.icon!,
                        color: isEnabled
                            ? config.color
                            : Colors.grey.withOpacity(0.5),
                        size: widget.compact ? 18 : 20,
                      ),
                    if (widget.showLabel) ...[
                      SizedBox(width: widget.compact ? 6 : 8),
                      Text(
                        config.label,
                        style: TextStyle(
                          color: isEnabled
                              ? config.color
                              : Colors.grey.withOpacity(0.5),
                          fontSize: widget.compact ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preset Styles
class HeaderPresets {
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
}