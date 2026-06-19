import '../models/parking_lot.dart';

const _op = 'ffce33c0-661c-47e1-98b1-b01515c0730f';

// Unsplash images — errorBuilder in widgets provides a premium gradient fallback
// if network is unavailable or a URL changes.
const _i1 = 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=800&q=80';
const _i2 = 'https://images.unsplash.com/photo-1573348722427-f1d6819fdc1a?auto=format&fit=crop&w=800&q=80';
const _i3 = 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=800&q=80';
const _i4 = 'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?auto=format&fit=crop&w=800&q=80';
const _i5 = 'https://images.unsplash.com/photo-1512621776951-a57ef97e4a51?auto=format&fit=crop&w=800&q=80';

const List<ParkingLot> demoLots = [
  ParkingLot(
    id: '1',
    operatorId: _op,
    name: 'Grand Canyon Parking',
    address: 'Derekh HaYam 1, Haifa',
    latitude: 32.8191,
    longitude: 35.0003,
    totalSpaces: 500,
    availableSpaces: 127,
    price: '7 ₪/hr',
    isOpen: true,
    distanceLabel: '0.3 km',
    openHours: 'Open 24/7',
    imageUrl: _i1,
    lastUpdated: '2 min ago',
  ),
  ParkingLot(
    id: '2',
    operatorId: _op,
    name: 'Rambam Parking',
    address: 'HaAliyah HaShniya 8, Haifa',
    latitude: 32.8078,
    longitude: 34.9893,
    totalSpaces: 300,
    availableSpaces: 18,
    price: '10 ₪/hr',
    isOpen: true,
    distanceLabel: '1.1 km',
    openHours: 'Open 06:00–22:00',
    imageUrl: _i2,
    lastUpdated: '1 min ago',
  ),
  ParkingLot(
    id: '3',
    operatorId: _op,
    name: 'Downtown Parking',
    address: "HaNevi'im 14, Haifa",
    latitude: 32.8232,
    longitude: 35.0092,
    totalSpaces: 200,
    availableSpaces: 0,
    price: '5 ₪/hr',
    isOpen: true,
    distanceLabel: '0.8 km',
    openHours: 'Open 24/7',
    imageUrl: _i3,
    lastUpdated: '5 min ago',
  ),
  ParkingLot(
    id: '4',
    operatorId: _op,
    name: 'Horev Center Parking',
    address: 'Moriah Blvd 12, Haifa',
    latitude: 32.8161,
    longitude: 35.0041,
    totalSpaces: 250,
    availableSpaces: 89,
    price: '8 ₪/hr',
    isOpen: true,
    distanceLabel: '0.5 km',
    openHours: 'Open 07:00–23:00',
    imageUrl: _i4,
    lastUpdated: '3 min ago',
  ),
  ParkingLot(
    id: '5',
    operatorId: _op,
    name: 'Bat Galim Parking',
    address: 'Ben Gurion Blvd 1, Haifa',
    latitude: 32.8314,
    longitude: 34.9782,
    totalSpaces: 100,
    availableSpaces: 0,
    price: '4 ₪/hr',
    isOpen: false,
    distanceLabel: '2.1 km',
    openHours: 'Opens 08:00 tomorrow',
    imageUrl: _i5,
    lastUpdated: '14 min ago',
  ),
];
