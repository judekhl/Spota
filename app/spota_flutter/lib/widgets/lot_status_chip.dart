import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';

const _green  = Color(0xFF34A853);
const _amber  = Color(0xFFF9AB00);
const _red    = Color(0xFFEA4335);
const _gray   = Color(0xFF9AA0A6);

(String, Color) statusProps(LotStatus s) => switch (s) {
  LotStatus.available => ('Available', _green),
  LotStatus.limited   => ('Limited',   _amber),
  LotStatus.full      => ('Full',      _red),
  LotStatus.closed    => ('Closed',    _gray),
};

class LotStatusChip extends StatelessWidget {
  final LotStatus status;
  // compact = inline dot + text; default = pill badge
  final bool compact;

  const LotStatusChip({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusProps(status);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
