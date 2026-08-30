import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.mutedText),
  );
}
