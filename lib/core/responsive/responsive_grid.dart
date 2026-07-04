import 'package:flutter/material.dart';
import 'responsive.dart';

class ResponsiveGrid {
  static int columns(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return 4;
    }

    if (Responsive.isTablet(context)) {
      return 3;
    }

    return 2;
  }

  static double spacing = 16;
}
