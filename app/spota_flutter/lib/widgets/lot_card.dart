import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';
import 'lot_status_chip.dart';

class LotCard extends StatelessWidget {
  final ParkingLot lot;
  final VoidCallback onTap;

  const LotCard({super.key, required this.lot, required this.onTap});

  Color get _accentColor {
    final (_, color) = statusProps(lot.status);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status accent bar
                Container(width: 4, color: _accentColor),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lot.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _PriceChip(price: lot.price),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lot.address,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF5F6368),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            LotStatusChip(status: lot.status, compact: true),
                            const Spacer(),
                            const Icon(Icons.near_me_outlined, size: 13, color: Color(0xFFBBBBBB)),
                            const SizedBox(width: 3),
                            Text(
                              lot.distanceLabel,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBBBBB)),
                            ),
                            if (lot.status == LotStatus.available || lot.status == LotStatus.limited) ...[
                              const SizedBox(width: 10),
                              Text(
                                '${lot.availableSpaces} free',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String price;
  const _PriceChip({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        price,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3C4043),
        ),
      ),
    );
  }
}
