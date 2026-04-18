import 'dart:async';

import 'package:shuttletrack/core/constants/app_constants.dart';
import 'package:shuttletrack/core/utils/geo_utils.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class MockTrackingDatasource {
  Timer? _simulationTimer;
  final _shuttleStreamController =
      StreamController<List<Shuttle>>.broadcast();

  late final List<ShuttleRoute> _routes;
  late final List<Shuttle> _shuttleDefinitions;
  late final Map<String, List<List<double>>> _routeWaypoints;
  final Map<String, int> _shuttleWaypointIndices = {};
  List<Shuttle> _currentShuttlePositions = [];

  MockTrackingDatasource() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _routes = _buildRoutes();
    _routeWaypoints = {
      for (final route in _routes)
        route.id: _buildWaypointsForRoute(route),
    };
    _shuttleDefinitions = _buildShuttles();

    for (final shuttle in _shuttleDefinitions) {
      _shuttleWaypointIndices[shuttle.id] = 0;
    }

    _currentShuttlePositions = List.of(_shuttleDefinitions);
  }

  List<ShuttleRoute> _buildRoutes() {
    final campusLoopStops = [
      const BusStop(
        id: 'campus_loop_stop_1',
        name: 'Main Gate',
        latitude: -25.7530,
        longitude: 28.2290,
        order: 1,
        routeId: 'campus_loop',
      ),
      const BusStop(
        id: 'campus_loop_stop_2',
        name: 'Engineering Building',
        latitude: -25.7510,
        longitude: 28.2340,
        order: 2,
        routeId: 'campus_loop',
      ),
      const BusStop(
        id: 'campus_loop_stop_3',
        name: 'Student Center',
        latitude: -25.7540,
        longitude: 28.2370,
        order: 3,
        routeId: 'campus_loop',
      ),
      const BusStop(
        id: 'campus_loop_stop_4',
        name: 'Library',
        latitude: -25.7570,
        longitude: 28.2360,
        order: 4,
        routeId: 'campus_loop',
      ),
      const BusStop(
        id: 'campus_loop_stop_5',
        name: 'Sports Complex',
        latitude: -25.7580,
        longitude: 28.2310,
        order: 5,
        routeId: 'campus_loop',
      ),
    ];

    final cityExpressStops = [
      const BusStop(
        id: 'city_express_stop_1',
        name: 'Campus North',
        latitude: -25.7500,
        longitude: 28.2320,
        order: 1,
        routeId: 'city_express',
      ),
      const BusStop(
        id: 'city_express_stop_2',
        name: 'Tech Park',
        latitude: -25.7450,
        longitude: 28.2350,
        order: 2,
        routeId: 'city_express',
      ),
      const BusStop(
        id: 'city_express_stop_3',
        name: 'Shopping Mall',
        latitude: -25.7400,
        longitude: 28.2380,
        order: 3,
        routeId: 'city_express',
      ),
      const BusStop(
        id: 'city_express_stop_4',
        name: 'City Center',
        latitude: -25.7350,
        longitude: 28.2400,
        order: 4,
        routeId: 'city_express',
      ),
    ];

    final residenceStops = [
      const BusStop(
        id: 'residence_stop_1',
        name: 'Campus South',
        latitude: -25.7600,
        longitude: 28.2330,
        order: 1,
        routeId: 'residence',
      ),
      const BusStop(
        id: 'residence_stop_2',
        name: 'Medical Center',
        latitude: -25.7630,
        longitude: 28.2300,
        order: 2,
        routeId: 'residence',
      ),
      const BusStop(
        id: 'residence_stop_3',
        name: 'Residence Hall A',
        latitude: -25.7660,
        longitude: 28.2280,
        order: 3,
        routeId: 'residence',
      ),
      const BusStop(
        id: 'residence_stop_4',
        name: 'Residence Hall B',
        latitude: -25.7690,
        longitude: 28.2310,
        order: 4,
        routeId: 'residence',
      ),
    ];

    return [
      ShuttleRoute(
        id: 'campus_loop',
        name: 'Campus Loop',
        description: 'Circular route around the University of Pretoria campus',
        colorHex: 'FF14532D',
        stops: campusLoopStops,
        polylineCoordinates: _polylineFromStops(campusLoopStops, isLoop: true),
      ),
      ShuttleRoute(
        id: 'city_express',
        name: 'City Express',
        description:
            'Express route from campus to the city center',
        colorHex: 'FF1565C0',
        stops: cityExpressStops,
        polylineCoordinates: _polylineFromStops(cityExpressStops),
      ),
      ShuttleRoute(
        id: 'residence',
        name: 'Residence Route',
        description: 'Route connecting campus to student residences',
        colorHex: 'FFF57C00',
        stops: residenceStops,
        polylineCoordinates: _polylineFromStops(residenceStops),
      ),
    ];
  }

  /// Generates a polyline from stop coordinates, optionally closing the loop.
  List<List<double>> _polylineFromStops(
    List<BusStop> stops, {
    bool isLoop = false,
  }) {
    final points = <List<double>>[];
    for (final stop in stops) {
      points.add([stop.latitude, stop.longitude]);
    }
    if (isLoop && stops.length > 1) {
      points.add([stops.first.latitude, stops.first.longitude]);
    }
    return points;
  }

  /// Builds dense waypoints for smooth simulation movement.
  /// Inserts 4 interpolated points between each consecutive stop pair.
  List<List<double>> _buildWaypointsForRoute(ShuttleRoute route) {
    final stops = route.stops;
    final isLoop = route.id == 'campus_loop';
    final waypoints = <List<double>>[];

    final stopCount = stops.length;
    final segmentCount = isLoop ? stopCount : stopCount - 1;

    for (var i = 0; i < segmentCount; i++) {
      final from = stops[i];
      final to = stops[(i + 1) % stopCount];

      waypoints.add([from.latitude, from.longitude]);

      final interpolated = GeoUtils.interpolate(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
        4,
      );
      for (final point in interpolated) {
        waypoints.add([point.$1, point.$2]);
      }
    }

    // For non-loop routes, include the final stop
    if (!isLoop) {
      final last = stops.last;
      waypoints.add([last.latitude, last.longitude]);
    }

    return waypoints;
  }

  List<Shuttle> _buildShuttles() {
    final now = DateTime.now();
    return [
      Shuttle(
        id: 'shuttle_1',
        name: 'Shuttle A',
        routeId: 'campus_loop',
        latitude: -25.7530,
        longitude: 28.2290,
        lastUpdated: now,
      ),
      Shuttle(
        id: 'shuttle_2',
        name: 'Shuttle B',
        routeId: 'city_express',
        latitude: -25.7500,
        longitude: 28.2320,
        lastUpdated: now,
      ),
      Shuttle(
        id: 'shuttle_3',
        name: 'Shuttle C',
        routeId: 'residence',
        latitude: -25.7600,
        longitude: 28.2330,
        lastUpdated: now,
      ),
      Shuttle(
        id: 'shuttle_4',
        name: 'Shuttle D',
        routeId: 'campus_loop',
        latitude: -25.7530,
        longitude: 28.2290,
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

      updated.add(shuttle.copyWith(
        latitude: nextLat,
        longitude: nextLng,
        heading: heading,
        speed: speed,
        lastUpdated: DateTime.now(),
      ));
    }

    _currentShuttlePositions = updated;
    _shuttleStreamController.add(updated);
  }

  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) {
    return _shuttleStreamController.stream.map(
      (shuttles) =>
          shuttles.where((s) => s.routeId == routeId).toList(),
    );
  }

  Future<List<Shuttle>> getActiveShuttles() async {
    return _currentShuttlePositions
        .where((s) => s.isActive)
        .toList();
  }

  Future<List<ShuttleRoute>> getRoutes() async => _routes;

  Future<ShuttleRoute?> getRoute(String routeId) async {
    return _routes
        .where((r) => r.id == routeId)
        .firstOrNull;
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
