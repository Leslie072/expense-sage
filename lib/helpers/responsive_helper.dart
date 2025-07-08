import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

enum ScreenSize {
  small,   // < 600px
  medium,  // 600px - 1024px
  large,   // > 1024px
}

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (width < mobileBreakpoint) return DeviceType.mobile;
      if (width < tabletBreakpoint) return DeviceType.tablet;
      return DeviceType.desktop;
    }
    
    // For mobile platforms, use platform detection
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      return width > tabletBreakpoint ? DeviceType.tablet : DeviceType.mobile;
    }
    
    return DeviceType.desktop;
  }

  // Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) return ScreenSize.small;
    if (width < tabletBreakpoint) return ScreenSize.medium;
    return ScreenSize.large;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  // Check if running on web
  static bool isWeb() {
    return kIsWeb;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }

  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(8);
      case DeviceType.tablet:
        return const EdgeInsets.all(16);
      case DeviceType.desktop:
        return const EdgeInsets.all(24);
    }
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseFontSize;
      case DeviceType.tablet:
        return baseFontSize * 1.1;
      case DeviceType.desktop:
        return baseFontSize * 1.2;
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseIconSize;
      case DeviceType.tablet:
        return baseIconSize * 1.2;
      case DeviceType.desktop:
        return baseIconSize * 1.4;
    }
  }

  // Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth - 32; // Full width with padding
      case DeviceType.tablet:
        return screenWidth * 0.8; // 80% of screen width
      case DeviceType.desktop:
        return 400; // Fixed width for desktop
    }
  }

  // Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }

  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth * 0.9;
      case DeviceType.tablet:
        return screenWidth * 0.7;
      case DeviceType.desktop:
        return 500;
    }
  }

  // Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tablet:
        return kToolbarHeight + 8;
      case DeviceType.desktop:
        return kToolbarHeight + 16;
    }
  }

  // Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 280; // Drawer width
      case DeviceType.tablet:
        return 300;
      case DeviceType.desktop:
        return 320;
    }
  }

  // Check if should use drawer navigation
  static bool shouldUseDrawer(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  // Check if should use rail navigation
  static bool shouldUseRail(BuildContext context) {
    return getDeviceType(context) != DeviceType.mobile;
  }

  // Get responsive layout constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return BoxConstraints(
          maxWidth: screenSize.width,
          maxHeight: screenSize.height,
        );
      case DeviceType.tablet:
        return BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.9,
        );
      case DeviceType.desktop:
        return const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 800,
        );
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing;
      case DeviceType.tablet:
        return baseSpacing * 1.25;
      case DeviceType.desktop:
        return baseSpacing * 1.5;
    }
  }

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 48;
      case DeviceType.tablet:
        return 52;
      case DeviceType.desktop:
        return 56;
    }
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseBorderRadius) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseBorderRadius;
      case DeviceType.tablet:
        return baseBorderRadius * 1.2;
      case DeviceType.desktop:
        return baseBorderRadius * 1.4;
    }
  }

  // Get responsive elevation
  static double getResponsiveElevation(BuildContext context, double baseElevation) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseElevation;
      case DeviceType.tablet:
        return baseElevation * 1.2;
      case DeviceType.desktop:
        return baseElevation * 1.5;
    }
  }

  // Get responsive list tile height
  static double getResponsiveListTileHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 72;
      case DeviceType.tablet:
        return 80;
      case DeviceType.desktop:
        return 88;
    }
  }

  // Get responsive card elevation
  static double getResponsiveCardElevation(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 4;
      case DeviceType.desktop:
        return 6;
    }
  }

  // Get responsive text scale factor
  static double getResponsiveTextScaleFactor(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
}

// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    return builder(context, deviceType);
  }
}

// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}
