import 'dart:math';

class GeoUtils {
  GeoUtils._();

  static double distanceInMeters(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double bearingBetween(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final y = sin(dLng) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLng);
    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Linear interpolation between two coordinate sets, returns `count`
  /// intermediate points (excluding endpoints).
  static List<(double lat, double lng)> interpolate(
    double lat1, double lng1,
    double lat2, double lng2,
    int count,
  ) {
    final points = <(double, double)>[];
    for (var i = 1; i <= count; i++) {
      final t = i / (count + 1);
      points.add((lat1 + (lat2 - lat1) * t, lng1 + (lng2 - lng1) * t));
    }
    return points;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;
}
