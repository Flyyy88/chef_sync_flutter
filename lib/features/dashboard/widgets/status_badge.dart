import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const StatusBadge({super.key, required this.label, required this.isActive});

  // Pill-style chip, matching the status chip design used on the
  // Restaurant / Tables screens for a consistent look across the app.
  // "Active" borrows the success color rather than the brand color so
  // status and brand don't compete for the same visual meaning.
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppStatusColors.successSurface : AppStatusColors.neutralSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? AppStatusColors.success : AppStatusColors.neutral,
          ),
        ),
      );
}
