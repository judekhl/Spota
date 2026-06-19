import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.primaryLight,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  );
}
