class PlaceSuggestion {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String provider; // 'predefined' | 'geoapify'

  const PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.provider,
  });
}
