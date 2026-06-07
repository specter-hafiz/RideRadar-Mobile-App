import 'package:firebase_database/firebase_database.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';

class RealtimeDatabaseShuttleDatasource {
  final FirebaseDatabase _database;

  RealtimeDatabaseShuttleDatasource({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) {
    return _database
        .ref('liveShuttles')
        .orderByChild('routeId')
        .equalTo(routeId)
        .onValue
        .map((event) => _parseShuttles(event.snapshot));
  }

  Future<List<Shuttle>> getActiveShuttles() async {
    final snapshot = await _database.ref('liveShuttles').get();
    return _parseShuttles(
      snapshot,
    ).where((shuttle) => shuttle.isActive).toList();
  }

  List<Shuttle> _parseShuttles(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value == null) return const [];

    if (value is Map) {
      return value.entries
          .map((entry) {
            final entryValue = entry.value;
            if (entryValue is Map) {
              final data = Map<String, dynamic>.from(
                Map<Object?, Object?>.from(entryValue),
              );
              return _parseShuttle(entry.key.toString(), data);
            }

            return null;
          })
          .whereType<Shuttle>()
          .where((shuttle) => shuttle.isActive)
          .toList();
    }

    return const [];
  }

  Shuttle _parseShuttle(String id, Map<String, dynamic> data) {
    final latitude = _readLatitude(data);
    final longitude = _readLongitude(data);

    return Shuttle(
      id: id,
      name: (data['name'] as String?) ?? 'Unknown Shuttle',
      routeId: (data['routeId'] as String?) ?? '',
      latitude: latitude,
      longitude: longitude,
      heading: _readDouble(data['heading']),
      speed: _readDouble(data['speed']),
      isActive: data['isActive'] as bool? ?? true,
      lastUpdated: _readLastUpdated(data['lastUpdated']),
    );
  }

  double _readLatitude(Map<String, dynamic> data) {
    final location = data['location'];
    if (location is Map) {
      final locationMap = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(location),
      );
      final lat = locationMap['latitude'] ?? locationMap['lat'];
      if (lat is num) return lat.toDouble();
    }

    final lat = data['latitude'] ?? data['lat'];
    return lat is num ? lat.toDouble() : 0.0;
  }

  double _readLongitude(Map<String, dynamic> data) {
    final location = data['location'];
    if (location is Map) {
      final locationMap = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(location),
      );
      final lng = locationMap['longitude'] ?? locationMap['lng'];
      if (lng is num) return lng.toDouble();
    }

    final lng = data['longitude'] ?? data['lng'];
    return lng is num ? lng.toDouble() : 0.0;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  DateTime _readLastUpdated(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
