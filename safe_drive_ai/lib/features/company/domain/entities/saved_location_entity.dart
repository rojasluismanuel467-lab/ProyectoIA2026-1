class SavedLocationEntity {
  const SavedLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final DateTime createdAt;
}
