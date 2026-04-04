import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveHelper {
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static double responsiveValue(BuildContext context,
      {required double mobile, double? tablet, double? desktop}) {
    DeviceType type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    DeviceType type = ResponsiveHelper.getDeviceType(context);
    if (type == DeviceType.desktop && desktop != null) return desktop!;
    if (type == DeviceType.tablet && tablet != null) return tablet!;
    return mobile;
  }
}
