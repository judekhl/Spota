enum LotStatus { available, limited, full, closed }

enum DataConfidence { recentlyUpdated, estimated, unknown }

extension DataConfidenceLabel on DataConfidence {
  String get label => switch (this) {
    DataConfidence.recentlyUpdated => 'Recently updated',
    DataConfidence.estimated       => 'Estimated',
    DataConfidence.unknown         => 'Unknown',
  };
}

class ParkingLot {
  final String id;
  final String operatorId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSpaces;
  final int availableSpaces;
  final String price;
  final bool isOpen;
  final String distanceLabel;
  final String openHours;
  final String imageUrl;
  final String lastUpdated;
  final DateTime? updatedAt;
  final String? openingHoursText;
  final String? phone;
  final String? sourceUrl;
  final String? dataSource;
  final String? verifiedStatus;

  const ParkingLot({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSpaces,
    required this.availableSpaces,
    required this.price,
    required this.isOpen,
    required this.distanceLabel,
    required this.openHours,
    required this.imageUrl,
    required this.lastUpdated,
    this.updatedAt,
    this.openingHoursText,
    this.phone,
    this.sourceUrl,
    this.dataSource,
    this.verifiedStatus,
  });

  bool get isVerified => verifiedStatus == 'verified';
  bool get isDemo     => verifiedStatus == 'demo';

  LotStatus get status {
    if (!isOpen) return LotStatus.closed;
    if (availableSpaces == 0) return LotStatus.full;
    if (availableSpaces / totalSpaces < 0.2) return LotStatus.limited;
    return LotStatus.available;
  }

  DataConfidence get confidence {
    if (updatedAt == null) return DataConfidence.unknown;
    final age = DateTime.now().difference(updatedAt!);
    if (age.inHours < 2)  return DataConfidence.recentlyUpdated;
    if (age.inHours < 72) return DataConfidence.estimated;
    return DataConfidence.unknown;
  }
}
