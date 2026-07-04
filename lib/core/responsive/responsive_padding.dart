import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Centralized horizontal padding scale so every screen keeps the same
/// spacing rhythm at each breakpoint:
/// Mobile: 16px · Tablet: 20-24px · Desktop: 32px
class ResponsivePadding {
  ResponsivePadding._();

  static double horizontal(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return horizontalForWidth(width);
  }

  static double horizontalForWidth(double width) {
    if (width >= Breakpoints.desktop) return 32;
    if (width >= Breakpoints.mobile) return 24;
    return 16;
  }
}
