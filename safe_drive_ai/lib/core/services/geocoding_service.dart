import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Servicio de geocoding usando Nominatim (OpenStreetMap) - Gratuito
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'SafeDriveAI/1.0';

  /// Busca direcciones por texto con opción de limitar a Colombia
  Future<List<GeocodingResult>> search(String query, {LatLng? nearLocation}) async {
    if (query.trim().isEmpty) return [];

    try {
      // Construir URL con parámetros de ubicación
      String url = '$_baseUrl/search?'
          'q=${Uri.encodeComponent(query)}&'
          'format=json&'
          'limit=5&'
          'addressdetails=1';
      
      // Priorizar Colombia y ubicación cercana
      if (nearLocation != null) {
        // Viewbox para priorizar área cercana (50km a la redonda)
        final latDelta = 0.45; // ~50km
        final lonDelta = 0.45;
        final viewbox = '${nearLocation.longitude - lonDelta},'
            '${nearLocation.latitude - latDelta},'
            '${nearLocation.longitude + lonDelta},'
            '${nearLocation.latitude + latDelta}';
        
        url += '&viewbox=$viewbox';
        url += '&bounded=1'; // Priorizar dentro del viewbox
      } else {
        // Si no hay ubicación, al menos limitar a Colombia
        url += '&countrycodes=co';
      }

      final response = await http.get(Uri.parse(url), headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => GeocodingResult.fromJson(item)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Obtiene dirección desde coordenadas (reverse geocoding)
  Future<String?> getAddressFromCoords(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?'
        'lat=$lat&'
        'lon=$lng&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (_) {}

    return null;
  }
}

/// Resultado de búsqueda de geocoding
class GeocodingResult {
  final String displayName;
  final double lat;
  final double lon;
  final String type;
  final String? country;

  GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.type,
    this.country,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return GeocodingResult(
      displayName: json['display_name'] as String ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
      type: json['type'] as String? ?? 'place',
      country: address?['country'] as String?,
    );
  }

  LatLng get latLng => LatLng(lat, lon);
}
