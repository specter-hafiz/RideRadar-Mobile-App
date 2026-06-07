import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shuttletrack/core/services/directions_service.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class FirestoreShuttleDatasource {
  final FirebaseFirestore _firestore;

  FirestoreShuttleDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ShuttleRoute>> getRoutes() async {
    final routeSnap = await _firestore
        .collection('routes')
        .where('isActive', isEqualTo: true)
        .get();

    return routeSnap.docs.map((doc) => _parseRoute(doc)).toList();
  }

  Future<ShuttleRoute?> getRoute(String routeId) async {
    // Optimization: Query the single document directly instead of fetching all routes
    final doc = await _firestore.collection('routes').doc(routeId).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['isActive'] != true) return null;

    return _parseRoute(doc);
  }

  /// Helper to convert a Firestore document into a ShuttleRoute entity
  ShuttleRoute _parseRoute(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // 1. Parse stops from an array of Maps inside the Route document
    final stopsList = data['stops'] as List<dynamic>? ?? [];
    final stops = stopsList.map((s) {
      final loc = s['location'] as GeoPoint;
      return BusStop(
        id:
            s['id']
                as String, // You can use a map/uuid for this inside the array
        name: s['name'] as String,
        latitude: loc.latitude,
        longitude: loc.longitude,
        order: s['order'] as int,
        routeId: doc.id,
      );
    }).toList();

    // Sort stops by order just in case they are out of sequence in the array
    stops.sort((a, b) => a.order.compareTo(b.order));

    // 2. Decode polyline string directly
    final encodedPolyline = data['encodedPolyline'] as String? ?? '';
    final polyPoints = DirectionsService.decodePolyline(encodedPolyline);

    return ShuttleRoute(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      colorHex: data['colorHex'] as String,
      stops: stops,
      polylineCoordinates: polyPoints,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Future<List<BusStop>> getAllStops() async {
    final routes = await getRoutes();
    final uniqueStops = <String, BusStop>{};

    for (final route in routes) {
      for (final stop in route.stops) {
        // We use a Map with the stop's ID as the key.
        // This automatically deduplicates stops if multiple routes share the exact same stop.
        uniqueStops[stop.id] ??= stop;
      }
    }

    return uniqueStops.values.toList();
  }
}
