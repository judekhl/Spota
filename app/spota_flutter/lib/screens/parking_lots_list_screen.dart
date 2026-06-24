import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../data/destinations.dart';
import '../data/lot_repository.dart';
import '../models/parking_lot.dart';
import '../models/place_suggestion.dart';
import '../services/place_search_service.dart';
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
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  double? _compassHeading;
  StreamSubscription<Position>? _positionStream;

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
    // Request location after first frame so MapController is wired up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserLocation());
  }

  @override
  void dispose() {
    _positionStream?.cancel();
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

      final isFull = l.isOpen && l.availableSpaces == 0;
      return 100.0
          - 20.0 * dist                   // distance: 1 km = −20 pts
          + (l.isVerified ? 8.0 : 0.0)   // trust boost
          - (l.isDemo ? 5.0 : 0.0)       // demo penalty
          + (l.isOpen ? 20.0 : -20.0)    // open/closed: large split
          - (isFull ? 40.0 : 0.0)        // full lot: strong penalty (≈ 2 km disadvantage)
          + 8.0 * availRatio              // availability: up to +8
          + confBonus;                    // data freshness: up to +5
    }

    final sorted = [...lots];
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  Future<void> _fetchUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showLocationFailed();
        return;
      }
      // isLocationServiceEnabled skipped: unreliable on Chrome/web.
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = ll);
      _mapController.move(ll, 15.0);
      if (_positionStream == null) _startHeadingStream();
    } catch (_) {
      if (mounted) _showLocationFailed();
    }
  }

  void _startHeadingStream() {
    // Subscribe to position stream for compass heading updates.
    // On web/desktop, pos.heading is NaN or -1 when unavailable — those are
    // silently ignored and the compass stays at the static north indicator.
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ),
      ).listen(
        (pos) {
          if (!mounted) return;
          final h = pos.heading;
          if (!h.isNaN && h >= 0) setState(() => _compassHeading = h);
        },
        onError: (_) {},
      );
    } catch (_) {
      // Heading sensor unavailable on this platform — compass stays at north.
    }
  }

  void _showLocationFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't get your location — showing Haifa",
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(Destination dest) {
    setState(() => _selectedDestination = dest);
    const zoom = 15.5;
    // Shift camera south so the pin appears in the visible area above the
    // bottom sheet (initialChildSize 0.26 covers the lower ~26% of the screen).
    // Target: pin at ~37% from top rather than the full-screen center (50%).
    final screenH = MediaQuery.of(context).size.height;
    final offsetPx = screenH * 0.13;
    final metersPerPx =
        156543.03392 * cos(dest.latitude * pi / 180) / pow(2, zoom);
    final latOffsetDeg = offsetPx * metersPerPx / 111320.0;
    _mapController.move(
      LatLng(dest.latitude - latOffsetDeg, dest.longitude),
      zoom,
    );
  }

  void _clearDestination() {
    setState(() => _selectedDestination = null);
    _mapController.move(
      _userLocation ?? const LatLng(32.794, 34.989),
      _userLocation != null ? 15.0 : 13.5,
    );
  }

  void _openDestinationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationPicker(
        onSelected: (dest) {
          Navigator.pop(context);
          // Wait for modal close animation before moving the camera.
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _selectDestination(dest);
          });
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
                        width: 52,
                        height: 52,
                        alignment: Alignment.bottomCenter,
                        child: const _DestinationPin(),
                      ),
                    ],
                  ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 24,
                        height: 24,
                        child: const _UserLocationDot(),
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
                    _FloatingIconBtn(icon: Icons.settings_rounded, onTap: () {}),
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

          // Right-side floating controls: compass + my-location
          Positioned(
            top: topPad + 132,
            right: 16,
            child: Column(
              children: [
                _CompassBtn(heading: _compassHeading),
                const SizedBox(height: 8),
                _FloatingIconBtn(icon: Icons.my_location_rounded, onTap: _fetchUserLocation),
              ],
            ),
          ),

          // Draggable bottom sheet with lot list
          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.13,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.13, 0.26, 0.93],
            builder: (_, controller) => _LotSheet(
              controller: controller,
              lots: displayedLots,
              loading: _loading,
              destination: _selectedDestination,
              userLocation: _userLocation,
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
              child: selected == null
                  ? Text(
                      'Where are you going?',
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selected!.name,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          selected!.area,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
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

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
        ),
        const CustomPaint(
          size: Size(14, 8),
          painter: _PinTipPainter(),
        ),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  const _PinTipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
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

class _CompassBtn extends StatelessWidget {
  final double? heading;
  const _CompassBtn({this.heading});

  @override
  Widget build(BuildContext context) {
    // heading null → no sensor data → needle stays pointing north (angle 0)
    final angle = heading != null ? -(heading! * pi / 180) : 0.0;
    return Container(
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
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          size: const Size(42, 42),
          painter: _CompassPainter(active: heading != null),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool active;
  const _CompassPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final arrowH = size.height * 0.33;
    final arrowW = size.width * 0.10;

    // North half — red when live heading is available, muted when static
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - arrowH)
        ..lineTo(cx - arrowW, cy)
        ..lineTo(cx + arrowW, cy)
        ..close(),
      Paint()
        ..color = active ? const Color(0xFFDC2626) : const Color(0xFFD1D5DB)
        ..style = PaintingStyle.fill,
    );
    // South half — always muted grey
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + arrowH)
        ..lineTo(cx - arrowW, cy)
        ..lineTo(cx + arrowW, cy)
        ..close(),
      Paint()
        ..color = const Color(0xFFD1D5DB)
        ..style = PaintingStyle.fill,
    );
    // Centre pivot dot
    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()..color = const Color(0xFF9CA3AF),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.active != active;
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

// ── Distance / walking-time helpers ──────────────────────────────────────────

double _lotDistKm(ParkingLot lot, double refLat, double refLon) {
  final dlat = (lot.latitude - refLat) * 111.0;
  final dlon = (lot.longitude - refLon) * 94.0;
  return sqrt(dlat * dlat + dlon * dlon);
}

String _formatDist(double km) {
  if (km < 1.0) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String _formatWalk(double km) {
  final mins = max(1, (km / 5.0 * 60).round());
  return '$mins min walk';
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _LotSheet extends StatelessWidget {
  final ScrollController controller;
  final List<ParkingLot> lots;
  final bool loading;
  final Destination? destination;
  final LatLng? userLocation;

  const _LotSheet({
    required this.controller,
    required this.lots,
    required this.loading,
    this.destination,
    this.userLocation,
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
                                : 'Parking near ${destination!.name}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destination == null
                                ? 'Sorted by availability and trust'
                                : 'Sorted by distance, availability, and trust',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
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

                    final bool hasCoords = lot.latitude != 0.0 && lot.longitude != 0.0;
                    final double? refLat = destination?.latitude ?? userLocation?.latitude;
                    final double? refLon = destination?.longitude ?? userLocation?.longitude;

                    String? distText;
                    String? walkText;
                    double? distKm;
                    if (hasCoords && refLat != null && refLon != null) {
                      distKm = _lotDistKm(lot, refLat, refLon);
                      distText = _formatDist(distKm);
                      if (destination != null) walkText = _formatWalk(distKm);
                    }

                    String? matchLabel;
                    Color matchLabelColor = AppColors.primary;
                    if (lot.isDemo) {
                      matchLabel = 'Demo data';
                      matchLabelColor = AppColors.limited;
                    } else if (destination != null) {
                      if (hasCoords && distKm != null) {
                        if (idx == 0) {
                          final isFull = lot.isOpen && lot.availableSpaces == 0;
                          if (isFull) {
                            matchLabel = 'Closest option';
                          } else {
                            matchLabel = distKm <= 2.0 ? 'Best match' : 'Closest available';
                          }
                        } else if (lot.isVerified) {
                          matchLabel = 'Farther but verified';
                        }
                      } else if (lot.isVerified) {
                        matchLabel = 'Farther but verified';
                      }
                    } else if (lot.isVerified) {
                      matchLabel = 'Verified';
                    }

                    return ParkingLotCard(
                      lot: lot,
                      matchLabel: matchLabel,
                      matchLabelColor: matchLabelColor,
                      distanceText: distText,
                      walkingText: walkText,
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
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _suggestions = PlaceSearchService.predefined('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    setState(() => _query = v);

    if (v.length < 2) {
      setState(() {
        _suggestions = PlaceSearchService.predefined(v);
        _isLoading = false;
      });
      return;
    }

    if (PlaceSearchService.hasApiKey) setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await PlaceSearchService.search(v);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    });
  }

  void _select(PlaceSuggestion s) {
    widget.onSelected(Destination(
      name: s.title,
      area: s.subtitle.isNotEmpty ? s.subtitle : 'Haifa',
      latitude: s.latitude,
      longitude: s.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isApiMode = PlaceSearchService.hasApiKey && _query.length >= 2;
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
                onChanged: _onQueryChanged,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search places in Haifa...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isApiMode ? 'Search results' : 'Quick destinations',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.38,
              ),
              child: _suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No places found',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: s.provider == 'predefined'
                                  ? AppColors.primaryLight
                                  : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              s.provider == 'predefined'
                                  ? Icons.location_on_rounded
                                  : Icons.place_rounded,
                              color: s.provider == 'predefined'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            s.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: s.subtitle.isNotEmpty
                              ? Text(
                                  s.subtitle,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                )
                              : null,
                          onTap: () => _select(s),
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
