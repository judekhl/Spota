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
    final lat = (r['latitude'] as num).toDouble();
    final lon = (r['longitude'] as num).toDouble();
    final isOpen = r['is_open'] as bool? ?? false;
    return ParkingLot(
      id: r['id'] as String,
      operatorId: r['operator_id'] as String? ?? '',
      name: r['name'] as String,
      address: r['address'] as String? ?? '',
      latitude: lat,
      longitude: lon,
      totalSpaces: r['total_spaces'] as int,
      availableSpaces: r['available_spaces'] as int,
      price: r['price'] as String? ?? '',
      isOpen: isOpen,
      distanceLabel: _distanceLabel(lat, lon),
      openHours: isOpen ? 'Open now' : 'Currently closed',
      imageUrl: '',
      lastUpdated: _timeAgo(r['updated_at'] as String?),
    );
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
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}
