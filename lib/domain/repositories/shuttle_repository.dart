import 'package:shuttletrack/domain/entities/shuttle.dart';

abstract class ShuttleRepository {
  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId);
  Future<List<Shuttle>> getActiveShuttles();
}
