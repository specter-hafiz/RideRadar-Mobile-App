import 'package:shuttletrack/data/datasources/firestore_shuttle_datasource.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/repositories/shuttle_repository.dart';

class ShuttleRepositoryImpl implements ShuttleRepository {
  final FirestoreShuttleDatasource _datasource;

  const ShuttleRepositoryImpl(this._datasource);

  @override
  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) =>
      _datasource.watchShuttlesOnRoute(routeId);

  @override
  Future<List<Shuttle>> getActiveShuttles() =>
      _datasource.watchShuttlesOnRoute('active').first;
}
