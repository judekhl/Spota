import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/destinations.dart';
import '../models/place_suggestion.dart';

class PlaceSearchService {
  static const _apiKey = String.fromEnvironment('GEOAPIFY_API_KEY');

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // Live autocomplete — falls back to predefined on any failure.
  static Future<List<PlaceSuggestion>> search(String query) async {
    if (query.length < 2 || !hasApiKey) return predefined(query);
    try {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
        'text': query,
        'limit': '6',
        'lang': 'en',
        'filter': 'countrycode:il',
        'bias': 'proximity:34.989,32.794',
        'apiKey': _apiKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return predefined(query);

      final data = json.decode(res.body) as Map<String, dynamic>;
      final features = (data['features'] as List<dynamic>?) ?? [];
      if (features.isEmpty) return predefined(query);

      return features.map((f) {
        final p = f['properties'] as Map<String, dynamic>;
        final name = (p['name'] as String?)?.isNotEmpty == true
            ? p['name'] as String
            : (p['address_line1'] as String?) ?? query;
        return PlaceSuggestion(
          title: name,
          subtitle: _subtitle(p),
          latitude: (p['lat'] as num).toDouble(),
          longitude: (p['lon'] as num).toDouble(),
          provider: 'geoapify',
        );
      }).toList();
    } catch (_) {
      return predefined(query);
    }
  }

  // Synchronous filter over the built-in Haifa destinations.
  static List<PlaceSuggestion> predefined(String query) {
    final q = query.toLowerCase().trim();
    return kHaifaDestinations
        .where((d) =>
            q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.area.toLowerCase().contains(q))
        .map((d) => PlaceSuggestion(
              title: d.name,
              subtitle: d.area,
              latitude: d.latitude,
              longitude: d.longitude,
              provider: 'predefined',
            ))
        .toList();
  }

  static String _subtitle(Map<String, dynamic> p) {
    final parts = <String>[];
    final suburb = p['suburb'] as String?;
    final district = p['district'] as String?;
    final city = p['city'] as String?;
    if (suburb?.isNotEmpty == true) {
      parts.add(suburb!);
    } else if (district?.isNotEmpty == true) {
      parts.add(district!);
    }
    if (city?.isNotEmpty == true && city != suburb) parts.add(city!);
    return parts.isNotEmpty
        ? parts.join(', ')
        : (p['address_line2'] as String?) ?? '';
  }
}
