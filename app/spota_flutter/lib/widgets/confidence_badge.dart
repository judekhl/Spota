import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';

class ConfidenceBadge extends StatelessWidget {
  final DataConfidence confidence;
  final bool small;
  const ConfidenceBadge({super.key, required this.confidence, this.small = false});

  Color get _bg => switch (confidence) {
    DataConfidence.recentlyUpdated => const Color(0xFFDCFCE7),
    DataConfidence.estimated       => const Color(0xFFFEF9C3),
    DataConfidence.unknown         => const Color(0xFFF3F4F6),
  };

  Color get _fg => switch (confidence) {
    DataConfidence.recentlyUpdated => const Color(0xFF15803D),
    DataConfidence.estimated       => const Color(0xFF92400E),
    DataConfidence.unknown         => const Color(0xFF6B7280),
  };

  IconData get _icon => switch (confidence) {
    DataConfidence.recentlyUpdated => Icons.check_circle_outline_rounded,
    DataConfidence.estimated       => Icons.access_time_rounded,
    DataConfidence.unknown         => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 10.0 : 11.0;
    final iconSize = small ? 10.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 7, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: iconSize, color: _fg),
          const SizedBox(width: 3),
          Text(
            confidence.label,
            style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: _fg),
          ),
        ],
      ),
    );
  }
}
