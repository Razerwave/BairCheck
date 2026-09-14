import 'app_enums.dart';

class Property {
  const Property({
    required this.id,
    required this.name,
    required this.address,
    required this.furnishingType,
    required this.areaSquareMeters,
    required this.floor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final FurnishingType furnishingType;
  final double areaSquareMeters;
  final int floor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'furnishing_type': furnishingType.databaseValue,
    'area_square_meters': areaSquareMeters,
    'floor': floor,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Property.fromJson(Map<String, Object?> json) => Property(
    id: json['id']! as String,
    name: json['name']! as String,
    address: json['address']! as String,
    furnishingType: FurnishingTypeX.fromDatabase(
      json['furnishing_type']! as String,
    ),
    areaSquareMeters: (json['area_square_meters']! as num).toDouble(),
    floor: (json['floor']! as num).toInt(),
    createdAt: DateTime.parse(json['created_at']! as String),
    updatedAt: DateTime.parse(json['updated_at']! as String),
  );
}
