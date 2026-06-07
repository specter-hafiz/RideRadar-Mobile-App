import 'package:shuttletrack/data/datasources/realtime_database_shuttle_datasource.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/repositories/shuttle_repository.dart';

class ShuttleRepositoryImpl implements ShuttleRepository {
  final RealtimeDatabaseShuttleDatasource _datasource;

  const ShuttleRepositoryImpl(this._datasource);

  @override
  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) =>
      _datasource.watchShuttlesOnRoute(routeId);

  @override
  Future<List<Shuttle>> getActiveShuttles() => _datasource.getActiveShuttles();
}
