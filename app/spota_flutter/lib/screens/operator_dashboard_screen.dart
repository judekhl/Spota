import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/demo_lots.dart';
import '../models/parking_lot.dart';
import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_badge.dart';

class _EditableLot {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final int totalSpaces;
  int availableSpaces;
  final String price;
  bool isOpen;

  _EditableLot({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.totalSpaces,
    required this.availableSpaces,
    required this.price,
    required this.isOpen,
  });
}

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  late final List<_EditableLot> _lots;

  @override
  void initState() {
    super.initState();
    _lots = demoLots
        .map((l) => _EditableLot(
              id: l.id,
              name: l.name,
              address: l.address,
              imageUrl: l.imageUrl,
              totalSpaces: l.totalSpaces,
              availableSpaces: l.availableSpaces,
              price: l.price,
              isOpen: l.isOpen,
            ))
        .toList();
  }

  LotStatus _status(_EditableLot l) {
    if (!l.isOpen) return LotStatus.closed;
    if (l.availableSpaces == 0) return LotStatus.full;
    if (l.availableSpaces / l.totalSpaces < 0.2) return LotStatus.limited;
    return LotStatus.available;
  }

  int get _totalAvailable => _lots.fold(0, (s, l) => s + (l.isOpen ? l.availableSpaces : 0));
  int get _openCount => _lots.where((l) => l.isOpen).length;
  int get _totalSpaces => _lots.fold(0, (s, l) => s + l.totalSpaces);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header card
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Demo Operator',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'D',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KPI metrics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Text(
                      'Overview',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Available',
                          value: '$_totalAvailable',
                          icon: Icons.local_parking_rounded,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'Total Spaces',
                          value: '$_totalSpaces',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'Lots Open',
                          value: '$_openCount / ${_lots.length}',
                          icon: Icons.store_mall_directory_outlined,
                          accentColor: _openCount > 0 ? AppColors.primary : AppColors.closed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
              child: Text(
                'My Lots',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ),

          // Lot control cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i.isOdd) return const SizedBox(height: 14);
                  final lot = _lots[i ~/ 2];
                  final status = _status(lot);
                  return _LotControlCard(
                    lot: lot,
                    status: status,
                    onDecrement: lot.isOpen && lot.availableSpaces > 0
                        ? () => setState(() => lot.availableSpaces--)
                        : null,
                    onIncrement: lot.isOpen && lot.availableSpaces < lot.totalSpaces
                        ? () => setState(() => lot.availableSpaces++)
                        : null,
                    onToggle: () => setState(() => lot.isOpen = !lot.isOpen),
                  );
                },
                childCount: _lots.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotControlCard extends StatelessWidget {
  final _EditableLot lot;
  final LotStatus status;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onToggle;

  const _LotControlCard({
    required this.lot,
    required this.status,
    required this.onDecrement,
    required this.onIncrement,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with lot name overlay
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    lot.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: statusColor.withValues(alpha: 0.15),
                      child: Center(child: Icon(Icons.local_parking_rounded, color: statusColor, size: 36)),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                        stops: [0.3, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lot.name,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: status),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Address + open/close toggle
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lot.address,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: lot.isOpen ? AppColors.availableLight : AppColors.closedLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: lot.isOpen ? AppColors.available : AppColors.closed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                lot.isOpen ? 'Open' : 'Closed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: lot.isOpen ? AppColors.available : AppColors.closed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Spaces counter
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available spaces',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${lot.availableSpaces}',
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / ${lot.totalSpaces}',
                                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
                            const SizedBox(width: 10),
                            _StepButton(icon: Icons.add_rounded, onTap: onIncrement, primary: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Price
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        lot.price,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  const _StepButton({required this.icon, this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFEEEEEE)
              : primary
                  ? AppColors.primary
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: (!disabled && !primary) ? Border.all(color: AppColors.border, width: 1.5) : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: primary
                        ? AppColors.primary.withValues(alpha: 0.28)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: disabled
              ? const Color(0xFFCCCCCC)
              : primary
                  ? Colors.white
                  : AppColors.primary,
        ),
      ),
    );
  }
}
