import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../data/lot_repository.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import '../widgets/parking_lot_card.dart';
import '../widgets/premium_search_bar.dart';
import 'parking_lot_details_screen.dart';

class ParkingLotsListScreen extends StatefulWidget {
  const ParkingLotsListScreen({super.key});

  @override
  State<ParkingLotsListScreen> createState() => _ParkingLotsListScreenState();
}

class _ParkingLotsListScreenState extends State<ParkingLotsListScreen> {
  List<ParkingLot> _lots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    LotRepository.fetchAll().then((lots) {
      if (!mounted) return;
      setState(() {
        _lots = lots;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          // Real OpenStreetMap with Supabase lot markers
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(32.794, 34.989),
                initialZoom: 13.5,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.pinchMove |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.spota.app',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: _lots
                      .where((l) => l.latitude != 0.0 && l.longitude != 0.0)
                      .map((lot) => Marker(
                            point: LatLng(lot.latitude, lot.longitude),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParkingLotDetailsScreen(lot: lot),
                                ),
                              ),
                              child: _MapPin(status: lot.status),
                            ),
                          ))
                      .toList(),
                ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
          ),

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
            builder: (_, controller) => _LotSheet(
              controller: controller,
              lots: _lots,
              loading: _loading,
            ),
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

class _MapPin extends StatelessWidget {
  final LotStatus status;
  const _MapPin({required this.status});

  Color get _color => switch (status) {
    LotStatus.available => const Color(0xFF16A34A),
    LotStatus.limited   => const Color(0xFFD97706),
    LotStatus.full      => const Color(0xFFDC2626),
    LotStatus.closed    => const Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1),
        ),
      ),
    );
  }
}

class _LotSheet extends StatelessWidget {
  final ScrollController controller;
  final List<ParkingLot> lots;
  final bool loading;
  const _LotSheet({required this.controller, required this.lots, required this.loading});

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
                          '${lots.length} lots',
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

          // Lot cards / loading / empty
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (lots.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_parking_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No lots found',
                      style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i.isOdd) return const SizedBox(height: 14);
                    final lot = lots[i ~/ 2];
                    return ParkingLotCard(
                      lot: lot,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ParkingLotDetailsScreen(lot: lot)),
                      ),
                    );
                  },
                  childCount: lots.length * 2 - 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
