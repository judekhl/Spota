enum LotStatus { available, limited, full, closed }

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
  });

  LotStatus get status {
    if (!isOpen) return LotStatus.closed;
    if (availableSpaces == 0) return LotStatus.full;
    if (availableSpaces / totalSpaces < 0.2) return LotStatus.limited;
    return LotStatus.available;
  }
}
