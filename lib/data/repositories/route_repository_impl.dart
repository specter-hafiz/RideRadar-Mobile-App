import 'package:shuttletrack/core/services/directions_service.dart';
import 'package:shuttletrack/data/datasources/firestore_shuttle_datasource.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final FirestoreShuttleDatasource _datasource;
  final DirectionsService _directionsService;

  const RouteRepositoryImpl(this._datasource, this._directionsService);

  @override
  Future<List<ShuttleRoute>> getRoutes() async {
    final routes = await _datasource.getRoutes();
    return Future.wait(routes.map((route) => _enrichRouteWithPolyline(route)));
  }

  @override
  Future<ShuttleRoute?> getRoute(String routeId) async {
    final route = await _datasource.getRoute(routeId);
    if (route == null) return null;
    return _enrichRouteWithPolyline(route);
  }

  Future<ShuttleRoute> _enrichRouteWithPolyline(ShuttleRoute route) async {
    // Treat fewer than 3 decoded points as a corrupt / missing polyline
    // so we fall through to the Directions API to draw the real road path.
    if (route.polylineCoordinates.length >= 3 || route.stops.length < 2) {
      return route;
    }

    try {
      final stopsCoords = route.stops.map((s) => [s.latitude, s.longitude]).toList();
      final polyPoints = await _directionsService.getRoutePolyline(stops: stopsCoords);
      return route.copyWith(polylineCoordinates: polyPoints);
    } catch (e) {
      // If Directions API fails, just return the route without a drawn polyline
      // (or it will draw straight lines if the UI is updated to do so, but currently UI returns {})
      return route;
    }
  }
}
