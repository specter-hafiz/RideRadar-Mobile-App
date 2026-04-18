import 'package:shuttletrack/domain/entities/shuttle_route.dart';

abstract class RouteRepository {
  Future<List<ShuttleRoute>> getRoutes();
  Future<ShuttleRoute?> getRoute(String routeId);
}
