import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';

extension LotStatusX on LotStatus {
  String get label => switch (this) {
        LotStatus.available => 'Available',
        LotStatus.limited   => 'Limited',
        LotStatus.full      => 'Full',
        LotStatus.closed    => 'Closed',
      };

  Color get color => switch (this) {
        LotStatus.available => AppColors.available,
        LotStatus.limited   => AppColors.limited,
        LotStatus.full      => AppColors.full,
        LotStatus.closed    => AppColors.closed,
      };

  Color get bgColor => switch (this) {
        LotStatus.available => AppColors.availableLight,
        LotStatus.limited   => AppColors.limitedLight,
        LotStatus.full      => AppColors.fullLight,
        LotStatus.closed    => AppColors.closedLight,
      };
}

class StatusBadge extends StatelessWidget {
  final LotStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final bg    = status.bgColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
