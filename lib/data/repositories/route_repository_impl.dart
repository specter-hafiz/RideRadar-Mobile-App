import 'package:shuttletrack/data/datasources/mock_tracking_datasource.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final MockTrackingDatasource _datasource;

  const RouteRepositoryImpl(this._datasource);

  @override
  Future<List<ShuttleRoute>> getRoutes() => _datasource.getRoutes();

  @override
  Future<ShuttleRoute?> getRoute(String routeId) =>
      _datasource.getRoute(routeId);
}
