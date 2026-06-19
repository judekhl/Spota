import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const background  = Color(0xFFF4F6F8);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F2F5);

  // Text
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted     = Color(0xFF9CA3AF);

  // Primary — elegant green
  static const primary      = Color(0xFF16A34A);
  static const primaryDark  = Color(0xFF15803D);
  static const primaryLight = Color(0xFFDCFCE7);

  // Status
  static const available      = Color(0xFF16A34A);
  static const availableLight = Color(0xFFDCFCE7);
  static const limited        = Color(0xFFD97706);
  static const limitedLight   = Color(0xFFFEF3C7);
  static const full           = Color(0xFFDC2626);
  static const fullLight      = Color(0xFFFEE2E2);
  static const closed         = Color(0xFF6B7280);
  static const closedLight    = Color(0xFFF3F4F6);

  // UI chrome
  static const border = Color(0xFFE5E7EB);
  static const shadow = Color(0x12000000);
}
