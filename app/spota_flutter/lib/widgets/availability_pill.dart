import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class AvailabilityPill extends StatelessWidget {
  final ParkingLot lot;

  const AvailabilityPill({super.key, required this.lot});

  @override
  Widget build(BuildContext context) {
    if (!lot.isOpen) {
      return Text(
        lot.openHours,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
      );
    }

    final color = lot.status.color;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${lot.availableSpaces}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          TextSpan(
            text: ' / ${lot.totalSpaces} free',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
