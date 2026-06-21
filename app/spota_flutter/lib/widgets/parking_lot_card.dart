import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import 'confidence_badge.dart';
import 'status_badge.dart';

class ParkingLotCard extends StatelessWidget {
  final ParkingLot lot;
  final VoidCallback onTap;
  final String? matchLabel;
  final Color matchLabelColor;

  const ParkingLotCard({
    super.key,
    required this.lot,
    required this.onTap,
    this.matchLabel,
    this.matchLabelColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (matchLabel != null)
                Container(
                  width: double.infinity,
                  color: matchLabelColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        matchLabel!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              _CardImage(lot: lot),
              _CardContent(lot: lot),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final ParkingLot lot;
  const _CardImage({required this.lot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'lot-img-${lot.id}',
            child: Image.network(
              lot.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ImageFallback(lot: lot),
            ),
          ),
          // Bottom gradient for text legibility
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x88000000)],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          // Status badge — top right
          Positioned(
            top: 12,
            right: 12,
            child: StatusBadge(status: lot.status),
          ),
          // Distance chip — top left
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me_rounded, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    lot.distanceLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final ParkingLot lot;
  const _CardContent({required this.lot});

  @override
  Widget build(BuildContext context) {
    final statusColor = lot.status.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lot.address,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _PriceChip(price: lot.price),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_parking_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 5),
              if (lot.isOpen)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${lot.availableSpaces} ',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                      TextSpan(
                        text: 'of ${lot.totalSpaces} free',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  lot.openHours,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                ),
              const Spacer(),
              ConfidenceBadge(confidence: lot.confidence, small: true),
              const SizedBox(width: 6),
              const Icon(Icons.update_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                lot.lastUpdated,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        price,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ParkingLot lot;
  const _ImageFallback({required this.lot});

  static const _gradients = [
    [Color(0xFF1A3A2A), Color(0xFF2D6A4F)],
    [Color(0xFF1A2A3A), Color(0xFF2D4A6A)],
    [Color(0xFF2A1A1A), Color(0xFF6A2D2D)],
    [Color(0xFF2A2A1A), Color(0xFF5A5A2D)],
    [Color(0xFF1A2A2A), Color(0xFF2D5A5A)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = lot.id.hashCode.abs() % _gradients.length;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[idx],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              lot.name,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
