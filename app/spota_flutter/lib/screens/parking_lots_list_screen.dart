import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/demo_lots.dart';
import '../theme/app_colors.dart';
import '../widgets/map_background.dart';
import '../widgets/parking_lot_card.dart';
import '../widgets/premium_search_bar.dart';
import 'parking_lot_details_screen.dart';

class ParkingLotsListScreen extends StatelessWidget {
  const ParkingLotsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          // Fake map — full screen
          const Positioned.fill(child: MapBackground()),

          // Floating header: branding + search bar
          Positioned(
            top: topPad + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Spota wordmark
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        'spota',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _FloatingIconBtn(
                      icon: Icons.my_location_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _FloatingIconBtn(
                      icon: Icons.notifications_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const PremiumSearchBar(),
              ],
            ),
          ),

          // Draggable bottom sheet with lot list
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.13,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.13, 0.48, 0.93],
            builder: (_, controller) => _LotSheet(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _FloatingIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FloatingIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.11), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _LotSheet extends StatelessWidget {
  final ScrollController controller;
  const _LotSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: Color(0x1C000000), blurRadius: 30, offset: Offset(0, -6)),
        ],
      ),
      child: CustomScrollView(
        controller: controller,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Handle + header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parking near you',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Haifa, Israel',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${demoLots.length} lots',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lot cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i.isOdd) return const SizedBox(height: 14);
                  final lot = demoLots[i ~/ 2];
                  return ParkingLotCard(
                    lot: lot,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ParkingLotDetailsScreen(lot: lot)),
                    ),
                  );
                },
                childCount: demoLots.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
