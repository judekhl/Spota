import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/report_repository.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/status_badge.dart';

class ParkingLotDetailsScreen extends StatefulWidget {
  final ParkingLot lot;
  const ParkingLotDetailsScreen({super.key, required this.lot});

  @override
  State<ParkingLotDetailsScreen> createState() => _ParkingLotDetailsScreenState();
}

class _ParkingLotDetailsScreenState extends State<ParkingLotDetailsScreen> {
  bool _submitting = false;
  String? _latestReportValue;
  DateTime? _latestReportAt;

  ParkingLot get lot => widget.lot;

  bool get _hasValidCoords => lot.latitude != 0.0 && lot.longitude != 0.0;

  Future<void> _openWaze() async {
    if (!_hasValidCoords) return;
    final uri = Uri.parse('https://www.waze.com/ul?ll=${lot.latitude},${lot.longitude}&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _openGoogleMaps() async {
    if (!_hasValidCoords) return;
    final uri = Uri.parse('https://maps.google.com/?q=${lot.latitude},${lot.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _submitReport(String value) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ReportRepository.submit(lotId: lot.id, reportValue: value);
      if (!mounted) return;
      setState(() {
        _latestReportValue = value;
        _latestReportAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your report!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Report submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit report. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _reportLabel(String value) => switch (value) {
    'empty'       => 'Empty',
    'some_spots'  => 'Some spots',
    'almost_full' => 'Almost full',
    'full'        => 'Full',
    _             => value,
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = lot.status.color;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero image header
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'lot-img-${lot.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      lot.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _HeroFallback(statusColor: statusColor),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x55000000), Colors.transparent, Color(0xCC000000)],
                          stops: [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: lot.status, large: true),
                          const SizedBox(height: 10),
                          Text(
                            lot.name,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lot.address,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI row
                Row(
                  children: [
                    _KpiCard(
                      label: 'Available',
                      value: lot.isOpen ? '${lot.availableSpaces}' : '—',
                      icon: Icons.local_parking_rounded,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    _KpiCard(
                      label: 'Total',
                      value: '${lot.totalSpaces}',
                      icon: Icons.grid_view_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    _KpiCard(
                      label: 'Price',
                      value: lot.price,
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Info tiles
                _InfoTile(icon: Icons.access_time_rounded, label: 'Hours',        value: lot.openHours),
                _InfoTile(icon: Icons.near_me_rounded,     label: 'Distance',     value: '${lot.distanceLabel} away'),
                _InfoTile(icon: Icons.update_rounded,      label: 'Last updated', value: lot.lastUpdated),
                _ConfidenceTile(confidence: lot.confidence),

                const SizedBox(height: 28),
                const Divider(color: AppColors.border),
                const SizedBox(height: 22),

                // Get directions
                Text(
                  'Get directions',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),

                if (!lot.isOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.closedLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: AppColors.closed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lot.openHours,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.closed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_hasValidCoords) ...[
                  _DirectionButton(
                    label: 'Navigate with Waze',
                    badge: 'W',
                    color: const Color(0xFF05C4EF),
                    onTap: _openWaze,
                  ),
                  const SizedBox(height: 12),
                  _DirectionButton(
                    label: 'Open in Google Maps',
                    badge: 'G',
                    color: const Color(0xFF4285F4),
                    onTap: _openGoogleMaps,
                  ),
                ] else
                  Text(
                    'No coordinates available for navigation.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),

                const SizedBox(height: 28),
                const Divider(color: AppColors.border),
                const SizedBox(height: 22),

                // Report section
                Text(
                  'Report what you see',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Help other drivers know the real situation',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _ReportGrid(submitting: _submitting, onReport: _submitReport),
                if (_latestReportValue != null && _latestReportAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Latest user report: ${_reportLabel(_latestReportValue!)} · ${_timeAgo(_latestReportAt!)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  final bool submitting;
  final void Function(String) onReport;
  const _ReportGrid({required this.submitting, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ReportButton(label: 'Empty',       icon: Icons.check_circle_outline_rounded, color: const Color(0xFF16A34A), value: 'empty',       submitting: submitting, onTap: onReport)),
            const SizedBox(width: 10),
            Expanded(child: _ReportButton(label: 'Some spots',  icon: Icons.directions_car_outlined,      color: const Color(0xFF2563EB), value: 'some_spots',  submitting: submitting, onTap: onReport)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _ReportButton(label: 'Almost full', icon: Icons.warning_amber_rounded,        color: const Color(0xFFD97706), value: 'almost_full', submitting: submitting, onTap: onReport)),
            const SizedBox(width: 10),
            Expanded(child: _ReportButton(label: 'Full',        icon: Icons.block_rounded,                color: const Color(0xFFDC2626), value: 'full',        submitting: submitting, onTap: onReport)),
          ],
        ),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final bool submitting;
  final void Function(String) onTap;
  const _ReportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.submitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: submitting ? null : () => onTap(value),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: submitting ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final Color statusColor;
  const _HeroFallback({required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor.withValues(alpha: 0.7), statusColor],
        ),
      ),
      child: Center(
        child: Icon(Icons.local_parking_rounded, size: 80, color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              Text(value,  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceTile extends StatelessWidget {
  final DataConfidence confidence;
  const _ConfidenceTile({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.verified_outlined, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data confidence', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 3),
              ConfidenceBadge(confidence: confidence),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final String badge;
  final Color color;
  final VoidCallback onTap;
  const _DirectionButton({required this.label, required this.badge, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(badge, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
