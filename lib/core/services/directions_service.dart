import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching route polyline coordinates from Google Directions API.
class DirectionsService {
  DirectionsService({required this.apiKey});

  final String apiKey;

  /// stops: [[lat, lng], [lat, lng], ...]
  /// Returns decoded polyline points as [[lat, lng], ...]
  Future<List<List<double>>> getRoutePolyline({
    required List<List<double>> stops,
    String travelMode = 'driving',
  }) async {
    if (stops.length < 2) return [];

    final origin = '${stops.first[0]},${stops.first[1]}';
    final destination = '${stops.last[0]},${stops.last[1]}';

    final waypointPoints = stops.sublist(1, stops.length - 1);
    final waypoints = waypointPoints.isEmpty
        ? null
        : waypointPoints.map((p) => '${p[0]},${p[1]}').join('|');

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': origin,
      'destination': destination,
      if (waypoints != null) 'waypoints': waypoints,
      'mode': travelMode,
      'key': apiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Directions API failed: HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK') {
      final message = body['error_message'];
      throw Exception('Directions API status: $status ${message ?? ''}');
    }

    final routes = body['routes'] as List<dynamic>;
    if (routes.isEmpty) return [];

    final overview = routes.first['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    print('\n\n--- ENCODED POLYLINE STRING ---');
    print(encoded);
    print('-------------------------------\n\n');
    if (encoded == null || encoded.isEmpty) return [];

    // Call the static method
    return decodePolyline(encoded);
  }

  /// Exposed as a static method so Firestore can use it without an API key
  static List<List<double>> decodePolyline(String encoded) {
    final points = <List<double>>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add([lat / 1E5, lng / 1E5]);
    }

    return points;
  }
}
