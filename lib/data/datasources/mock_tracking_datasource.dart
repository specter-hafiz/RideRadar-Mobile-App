import 'dart:async';

import 'package:shuttletrack/core/constants/app_constants.dart';
import 'package:shuttletrack/core/services/directions_service.dart';
import 'package:shuttletrack/core/utils/geo_utils.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class MockTrackingDatasource {
  MockTrackingDatasource({required DirectionsService directionsService})
    : _directionsService = directionsService;

  final DirectionsService _directionsService;

  Timer? _simulationTimer;
  final _shuttleStreamController = StreamController<List<Shuttle>>.broadcast();
  bool _initialized = false;
  late List<ShuttleRoute> _routes;
  late final List<Shuttle> _shuttleDefinitions;
  late Map<String, List<List<double>>> _routeWaypoints;
  final Map<String, int> _shuttleWaypointIndices = {};
  List<Shuttle> _currentShuttlePositions = [];

  Future<void> init() async {
    if (_initialized) return;
    _routes = await _buildRoutes();
    _routeWaypoints = {
      for (final route in _routes) route.id: _buildWaypointsForRoute(route),
    };
    _shuttleDefinitions = _buildShuttles();

    for (final shuttle in _shuttleDefinitions) {
      _shuttleWaypointIndices[shuttle.id] = 0;
    }

    _currentShuttlePositions = List.of(_shuttleDefinitions);
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<List<ShuttleRoute>> _buildRoutes() async {
    final cToKSBStops = [
      const BusStop(
        id: 'c2KSB_stop_1',
        name: 'Commercial Area',
        latitude: 6.682740,
        longitude: -1.576994,
        order: 1,
        routeId: 'c2KSB',
      ),
      const BusStop(
        id: 'c2KSB_stop_2',
        name: 'Hall 7 Front',
        latitude: 6.679293,
        longitude: -1.572800,
        order: 2,
        routeId: 'c2KSB',
      ),
      const BusStop(
        id: 'c2KSB_stop_3',
        name: 'Pharmacy Stop',
        latitude: 6.674538,
        longitude: -1.567575,
        order: 3,
        routeId: 'c2KSB',
      ),
      const BusStop(
        id: 'c2KSB_stop_4',
        name: 'KSB Stop',
        latitude: 6.669322,
        longitude: -1.567175,
        order: 4,
        routeId: 'c2KSB',
      ),
    ];

    final brunei2KSBStops = [
      const BusStop(
        id: 'brunei2KSB_stop_1',
        name: 'Brunei',
        latitude: 6.670441,
        longitude: -1.574152,
        order: 1,
        routeId: 'brunei2KSB',
      ),
      const BusStop(
        id: 'brunei2KSB_stop_2',
        name: 'Prempeh II Library',
        latitude: 6.675086,
        longitude: -1.572899,
        order: 2,
        routeId: 'brunei2KSB',
      ),
      const BusStop(
        id: 'brunei2KSB_stop_3',
        name: 'Pharmacy Stop',
        latitude: 6.674538,
        longitude: -1.567575,
        order: 3,
        routeId: 'brunei2KSB',
      ),
      const BusStop(
        id: 'brunei2KSB_stop_4',
        name: 'KSB Stop',
        latitude: 6.669322,
        longitude: -1.567175,
        order: 4,
        routeId: 'brunei2KSB',
      ),
    ];

    final agric2MVillageStops = [
      const BusStop(
        id: 'agric2MVillage_stop_1',
        name: 'Agric Stop',
        latitude: 6.674820,
        longitude: -1.566526,
        order: 1,
        routeId: 'agric2MVillage',
      ),
      const BusStop(
        id: 'agric2MVillage_stop_2',
        name: 'Gaza',
        latitude: 6.687602,
        longitude: -1.557034,
        order: 2,
        routeId: 'agric2MVillage',
      ),
      const BusStop(
        id: 'agric2MVillage_stop_3',
        name: 'Medical Village',
        latitude: 6.681121,
        longitude: -1.549854,
        order: 3,
        routeId: 'agric2MVillage',
      ),
    ];

    Future<List<List<double>>> realPolyline(List<BusStop> stops) async {
      final coords = stops.map((s) => [s.latitude, s.longitude]).toList();
      try {
        return await _directionsService.getRoutePolyline(stops: coords);
      } catch (_) {
        // Fallback: connect stops directly if API fails
        return coords;
      }
    }

    final c2KSBPolyline = await realPolyline(cToKSBStops);
    final bruneiPolyline = await realPolyline(brunei2KSBStops);
    final agricPolyline = await realPolyline(agric2MVillageStops);

    return [
      ShuttleRoute(
        id: 'c2KSB',
        name: 'Commercial Area - KSB',
        description: 'Route from Commercial Area to KSB',
        colorHex: 'FF14532D',
        stops: cToKSBStops,
        polylineCoordinates: c2KSBPolyline,
      ),
      ShuttleRoute(
        id: 'brunei2KSB',
        name: 'Brunei - KSB',
        description: 'Route from Brunei to KSB',
        colorHex: 'FF1565C0',
        stops: brunei2KSBStops,
        polylineCoordinates: bruneiPolyline,
      ),
      ShuttleRoute(
        id: 'agric2MVillage',
        name: 'Agric - Medical Village',
        description: 'Route from Agric to Medical Village',
        colorHex: 'FFF57C00',
        stops: agric2MVillageStops,
        polylineCoordinates: agricPolyline,
      ),
    ];
  }

  /// Build simulation waypoints from the decoded road polyline.
  /// This follows roads instead of straight stop-to-stop interpolation.
  List<List<double>> _buildWaypointsForRoute(ShuttleRoute route) {
    final polyline = route.polylineCoordinates;
    if (polyline.isEmpty) return [];
    return polyline;
  }

  List<Shuttle> _buildShuttles() {
    final now = DateTime.now();
    return [
      Shuttle(
        id: 'shuttle_1',
        name: 'Commercial Area - KSB',
        routeId: 'c2KSB',
        latitude: 6.682740,
        longitude: -1.576994,
        lastUpdated: now,
      ),
      Shuttle(
        id: 'shuttle_2',
        name: 'Brunei - KSB',
        routeId: 'brunei2KSB',
        latitude: 6.670441,
        longitude: -1.574152,
        lastUpdated: now,
      ),
      Shuttle(
        id: 'shuttle_3',
        name: 'Agric - Medical Village',
        routeId: 'agric2MVillage',
        latitude: 6.674820,
        longitude: -1.566526,
        lastUpdated: now,
      ),
    ];
  }

  void startSimulation() {
    if (_simulationTimer != null) return;

    _simulationTimer = Timer.periodic(
      AppConstants.simulationTickInterval,
      (_) => _tick(),
    );
  }

  void _tick() {
    final tickSeconds = AppConstants.simulationTickInterval.inSeconds;
    final updated = <Shuttle>[];

    for (var i = 0; i < _currentShuttlePositions.length; i++) {
      final shuttle = _currentShuttlePositions[i];
      if (!shuttle.isActive) {
        updated.add(shuttle);
        continue;
      }

      final waypoints = _routeWaypoints[shuttle.routeId];
      if (waypoints == null || waypoints.isEmpty) {
        updated.add(shuttle);
        continue;
      }

      final currentIndex = _shuttleWaypointIndices[shuttle.id] ?? 0;
      final nextIndex = (currentIndex + 1) % waypoints.length;
      _shuttleWaypointIndices[shuttle.id] = nextIndex;

      final nextPoint = waypoints[nextIndex];
      final nextLat = nextPoint[0];
      final nextLng = nextPoint[1];

      final lookAheadIndex = (nextIndex + 1) % waypoints.length;
      final lookAheadPoint = waypoints[lookAheadIndex];
      final heading = GeoUtils.bearingBetween(
        nextLat,
        nextLng,
        lookAheadPoint[0],
        lookAheadPoint[1],
      );

      final distance = GeoUtils.distanceInMeters(
        shuttle.latitude,
        shuttle.longitude,
        nextLat,
        nextLng,
      );
      final speed = tickSeconds > 0 ? distance / tickSeconds : 0.0;

      updated.add(
        shuttle.copyWith(
          latitude: nextLat,
          longitude: nextLng,
          heading: heading,
          speed: speed,
          lastUpdated: DateTime.now(),
        ),
      );
    }

    _currentShuttlePositions = updated;
    _shuttleStreamController.add(updated);
  }

  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) {
    return _shuttleStreamController.stream.map(
      (shuttles) => shuttles.where((s) => s.routeId == routeId).toList(),
    );
  }

  Future<List<Shuttle>> getActiveShuttles() async {
    await _ensureInitialized();
    return _currentShuttlePositions.where((s) => s.isActive).toList();
  }

  Future<List<ShuttleRoute>> getRoutes() async =>
      await _ensureInitialized().then((_) => _routes);

  Future<ShuttleRoute?> getRoute(String routeId) async {
    await _ensureInitialized();
    return _routes.where((r) => r.id == routeId).firstOrNull;
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopSimulation();
    _shuttleStreamController.close();
  }
}
