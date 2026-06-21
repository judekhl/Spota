class Destination {
  final String name;
  final String area;
  final double latitude;
  final double longitude;

  const Destination({
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
  });
}

const List<Destination> kHaifaDestinations = [
  Destination(name: 'Rambam Hospital',  area: 'Bat Galim',      latitude: 32.8234, longitude: 34.9846),
  Destination(name: 'Technion',         area: "Neve Sha'anan",   latitude: 32.7780, longitude: 35.0212),
  Destination(name: 'German Colony',    area: 'Lower City',      latitude: 32.8116, longitude: 34.9947),
  Destination(name: 'MATAM Tech Park',  area: 'Southern Haifa',  latitude: 32.7933, longitude: 34.9611),
  Destination(name: 'Downtown Haifa',   area: 'Hadar',           latitude: 32.8155, longitude: 34.9995),
  Destination(name: 'Hadar',            area: 'Central Haifa',   latitude: 32.8191, longitude: 35.0003),
  Destination(name: "Baha'i Gardens",   area: 'Persian Garden',  latitude: 32.8141, longitude: 34.9907),
];
