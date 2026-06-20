import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class ReportRepository {
  static Future<void> submit({
    required String lotId,
    required String reportValue,
  }) async {
    try {
      await Supabase.instance.client.from('parking_reports').insert({
        'parking_lot_id': lotId,
        'report_value': reportValue,
      });
    } catch (e) {
      debugPrint('[ReportRepository] insert error: $e');
      rethrow;
    }
  }
}
