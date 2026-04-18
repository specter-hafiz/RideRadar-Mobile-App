import 'package:shuttletrack/data/datasources/mock_tracking_datasource.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/repositories/shuttle_repository.dart';

class ShuttleRepositoryImpl implements ShuttleRepository {
  final MockTrackingDatasource _datasource;

  const ShuttleRepositoryImpl(this._datasource);

  @override
  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) =>
      _datasource.watchShuttlesOnRoute(routeId);

  @override
  Future<List<Shuttle>> getActiveShuttles() =>
      _datasource.getActiveShuttles();

  @override
  void startSimulation() => _datasource.startSimulation();

  @override
  void stopSimulation() => _datasource.stopSimulation();

  @override
  void dispose() => _datasource.dispose();
}
