import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../data/destinations.dart';
import '../data/lot_repository.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import '../widgets/parking_lot_card.dart';
import 'parking_lot_details_screen.dart';

class ParkingLotsListScreen extends StatefulWidget {
  const ParkingLotsListScreen({super.key});

  @override
  State<ParkingLotsListScreen> createState() => _ParkingLotsListScreenState();
}

class _ParkingLotsListScreenState extends State<ParkingLotsListScreen> {
  List<ParkingLot> _lots = [];
  bool _loading = true;
  Destination? _selectedDestination;
  final MapController _mapController = MapController();

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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<ParkingLot> get _displayedLots {
    final dest = _selectedDestination;
    if (dest == null) return _lots;
    return _rankLots(_lots, dest);
  }

  List<ParkingLot> _rankLots(List<ParkingLot> lots, Destination dest) {
    bool hasCoords(ParkingLot l) => l.latitude != 0.0 && l.longitude != 0.0;

    double distKm(ParkingLot l) {
      final dlat = (l.latitude - dest.latitude) * 111.0;
      final dlon = (l.longitude - dest.longitude) * 94.0;
      return sqrt(dlat * dlat + dlon * dlon);
    }

    double score(ParkingLot l) {
      // No coordinates = useless for destination search. Always sink below
      // every located lot, even one that is many km away.
      if (!hasCoords(l)) {
        return -100.0
            + (l.isVerified ? 8.0 : 0.0)
            - (l.isDemo ? 5.0 : 0.0)
            + (l.isOpen ? 10.0 : 0.0);
      }

      final dist = distKm(l);
      final availRatio = l.totalSpaces > 0
          ? l.availableSpaces / l.totalSpaces
          : 0.0;
      final confBonus = switch (l.confidence) {
        DataConfidence.recentlyUpdated => 5.0,
        DataConfidence.estimated       => 2.0,
        DataConfidence.unknown         => 0.0,
      };

      return 100.0
          - 20.0 * dist                  // distance is dominant: 1 km = −20 pts
          + (l.isVerified ? 8.0 : 0.0)  // trust boost ≈ 0.4 km equivalent
          - (l.isDemo ? 5.0 : 0.0)      // demo penalty ≈ 0.25 km equivalent
          + (l.isOpen ? 20.0 : -20.0)   // open/closed: large split
          + 8.0 * availRatio             // availability: up to +8
          + confBonus;                   // data freshness: up to +5
    }

    final sorted = [...lots];
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  void _selectDestination(Destination dest) {
    setState(() => _selectedDestination = dest);
    _mapController.move(LatLng(dest.latitude, dest.longitude), 14.5);
  }

  void _clearDestination() {
    setState(() => _selectedDestination = null);
    _mapController.move(const LatLng(32.794, 34.989), 13.5);
  }

  void _openDestinationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationPicker(
        onSelected: (dest) {
          Navigator.pop(context);
          _selectDestination(dest);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final displayedLots = _displayedLots;
    return Scaffold(
      body: Stack(
        children: [
          // Real OpenStreetMap with Supabase lot markers
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
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
                if (_selectedDestination != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _selectedDestination!.latitude,
                          _selectedDestination!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: _DestinationPin(),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
          ),

          // Floating header: branding + destination search
          Positioned(
            top: topPad + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                    _FloatingIconBtn(icon: Icons.my_location_rounded, onTap: () {}),
                    const SizedBox(width: 8),
                    _FloatingIconBtn(icon: Icons.notifications_outlined, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 10),
                _DestinationBar(
                  selected: _selectedDestination,
                  onTap: _openDestinationPicker,
                  onClear: _clearDestination,
                ),
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
              lots: displayedLots,
              loading: _loading,
              destination: _selectedDestination,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Destination search bar ────────────────────────────────────────────────────

class _DestinationBar extends StatelessWidget {
  final Destination? selected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DestinationBar({
    required this.selected,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Icon(
              selected == null ? Icons.search_rounded : Icons.location_on_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.name ?? 'Where are you going?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: selected == null ? AppColors.textMuted : AppColors.textPrimary,
                  fontWeight: selected == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                ),
              )
            else
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
      ),
    );
  }
}

// ── Map pins ──────────────────────────────────────────────────────────────────

class _DestinationPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, size: 16, color: Colors.white),
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.11),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
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

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _LotSheet extends StatelessWidget {
  final ScrollController controller;
  final List<ParkingLot> lots;
  final bool loading;
  final Destination? destination;

  const _LotSheet({
    required this.controller,
    required this.lots,
    required this.loading,
    this.destination,
  });

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
                            destination == null
                                ? 'Parking near you'
                                : 'Near ${destination!.name}',
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
                                destination == null ? 'Haifa, Israel' : destination!.area,
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
                    final idx = i ~/ 2;
                    final lot = lots[idx];
                    String? matchLabel;
                    Color matchLabelColor = AppColors.primary;
                    if (destination != null && idx == 0) {
                      // "Best match" only when: has coords, within 2 km, AND
                      // not demo (demo lots must always show their warning label).
                      final hasC = lot.latitude != 0.0 && lot.longitude != 0.0;
                      if (hasC && !lot.isDemo) {
                        final dlat = (lot.latitude - destination!.latitude) * 111.0;
                        final dlon = (lot.longitude - destination!.longitude) * 94.0;
                        final dist = sqrt(dlat * dlat + dlon * dlon);
                        if (dist <= 2.0) matchLabel = 'Best match';
                      }
                    }
                    if (matchLabel == null) {
                      if (lot.isVerified) {
                        matchLabel = 'Verified';
                      } else if (lot.isDemo) {
                        matchLabel = 'Demo data';
                        matchLabelColor = AppColors.limited;
                      }
                    }
                    return ParkingLotCard(
                      lot: lot,
                      matchLabel: matchLabel,
                      matchLabelColor: matchLabelColor,
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

// ── Destination picker modal ──────────────────────────────────────────────────

class _DestinationPicker extends StatefulWidget {
  final void Function(Destination) onSelected;
  const _DestinationPicker({required this.onSelected});

  @override
  State<_DestinationPicker> createState() => _DestinationPickerState();
}

class _DestinationPickerState extends State<_DestinationPicker> {
  String _query = '';

  List<Destination> get _filtered => kHaifaDestinations.where((d) {
        final q = _query.toLowerCase();
        return d.name.toLowerCase().contains(q) || d.area.toLowerCase().contains(q);
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Where are you going?',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.38,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final dest = _filtered[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    ),
                    title: Text(
                      dest.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      dest.area,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: () => widget.onSelected(dest),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
