import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Where are you going?',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
