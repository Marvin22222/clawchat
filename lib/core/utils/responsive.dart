import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Responsive helpers for adaptive layouts
class Responsive {
  /// Check if current screen width is mobile (< 600)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppDimensions.mobileBreakpoint;

  /// Check if current screen width is tablet (600 - 900)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppDimensions.mobileBreakpoint && width < AppDimensions.tabletBreakpoint;
  }

  /// Check if current screen width is desktop (>= 900)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.tabletBreakpoint;

  /// Check if current screen width is large desktop (>= 1200)
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.desktopBreakpoint;

  /// Get current screen width
  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  /// Get current screen height
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(AppSpacing.md),
      tablet: const EdgeInsets.all(AppSpacing.lg),
      desktop: const EdgeInsets.all(AppSpacing.xl),
    );
  }

  /// Get responsive crossAxisCount for grid views
  static int gridCrossAxisCount(BuildContext context) {
    return value(context, mobile: 1, tablet: 2, desktop: 3);
  }
}

/// Mixin to make widgets responsive
mixin ResponsiveMixin<T extends StatefulWidget> on State<T> {
  bool get isMobile => Responsive.isMobile(context);
  bool get isTablet => Responsive.isTablet(context);
  bool get isDesktop => Responsive.isDesktop(context);
  bool get isLargeDesktop => Responsive.isLargeDesktop(context);
}