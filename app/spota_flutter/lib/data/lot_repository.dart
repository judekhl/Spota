import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_env.dart';
import '../models/parking_lot.dart';

abstract final class LotRepository {
  static Future<List<ParkingLot>> fetchAll() async {
    if (!SupabaseEnv.isConfigured) return [];

    try {
      final rows = await Supabase.instance.client
          .from('parking_lots')
          .select()
          .order('name', ascending: true);
      return rows.map(_fromRow).toList();
    } catch (e) {
      return [];
    }
  }

  static ParkingLot _fromRow(Map<String, dynamic> r) {
    final lat = (r['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (r['longitude'] as num?)?.toDouble() ?? 0.0;
    final isOpen = r['is_open'] as bool? ?? false;
    final updatedAt = _parseDate(r['updated_at'] as String?);
    return ParkingLot(
      id: r['id'] as String,
      operatorId: r['operator_id'] as String? ?? '',
      name: r['name'] as String,
      address: r['address'] as String? ?? '',
      latitude: lat,
      longitude: lon,
      totalSpaces: (r['total_spaces'] as int?) ?? 0,
      availableSpaces: (r['available_spaces'] as int?) ?? 0,
      price: r['price'] as String? ?? '',
      isOpen: isOpen,
      distanceLabel: _distanceLabel(lat, lon),
      openHours: isOpen ? 'Open now' : 'Currently closed',
      imageUrl: '',
      lastUpdated: _timeAgo(r['updated_at'] as String?),
      updatedAt: updatedAt,
      openingHoursText: r['opening_hours_text'] as String?,
      phone: r['phone'] as String?,
      sourceUrl: r['source_url'] as String?,
      dataSource: r['data_source'] as String?,
      verifiedStatus: r['verified_status'] as String?,
    );
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _distanceLabel(double lat, double lon) {
    const refLat = 32.794;
    const refLon = 34.989;
    final dlat = (lat - refLat) * 111.0;
    final dlon = (lon - refLon) * 94.0;
    final km = sqrt(dlat * dlat + dlon * dlon);
    if (km < 1.0) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return 'Unknown';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}
