import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/saved_location_entity.dart';

class SavedLocationModel extends SavedLocationEntity {
  const SavedLocationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.lat,
    required super.lng,
    required super.createdAt,
  });

  factory SavedLocationModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return SavedLocationModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
