import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/core/utils/geo_utils.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/domain/repositories/route_repository.dart';
import 'package:shuttletrack/domain/repositories/shuttle_repository.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final ShuttleRepository _shuttleRepository;
  final RouteRepository _routeRepository;
  final double geofenceRadius;

  StreamSubscription<List<Shuttle>>? _shuttleSubscription;
  final Set<String> _recentlyNotifiedStopIds = {};

  TrackingBloc({
    required ShuttleRepository shuttleRepository,
    required RouteRepository routeRepository,
    this.geofenceRadius = 100.0,
  })  : _shuttleRepository = shuttleRepository,
        _routeRepository = routeRepository,
        super(const TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<_ShuttlePositionsUpdated>(_onShuttlePositionsUpdated);
  }

  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingLoading());

    try {
      _shuttleRepository.startSimulation();

      final route = await _routeRepository.getRoute(event.routeId);
      if (route == null) {
        emit(const TrackingError('Route not found'));
        return;
      }

      await _shuttleSubscription?.cancel();
      _recentlyNotifiedStopIds.clear();

      _shuttleSubscription = _shuttleRepository
          .watchShuttlesOnRoute(event.routeId)
          .listen((shuttles) {
        add(_ShuttlePositionsUpdated(shuttles: shuttles, route: route));
      });
    } catch (e) {
      emit(TrackingError(e.toString()));
    }
  }

  Future<void> _onStopTracking(
    StopTracking event,
    Emitter<TrackingState> emit,
  ) async {
    await _shuttleSubscription?.cancel();
    _shuttleSubscription = null;
    _shuttleRepository.stopSimulation();
    _recentlyNotifiedStopIds.clear();
    emit(const TrackingInitial());
  }

  void _onShuttlePositionsUpdated(
    _ShuttlePositionsUpdated event,
    Emitter<TrackingState> emit,
  ) {
    final currentProximityKeys = <String>{};
    final newProximity = <String, BusStop>{};

    for (final shuttle in event.shuttles) {
      for (final stop in event.route.stops) {
        final distance = GeoUtils.distanceInMeters(
          shuttle.latitude,
          shuttle.longitude,
          stop.latitude,
          stop.longitude,
        );

        if (distance <= geofenceRadius) {
          final key = '${shuttle.id}_${stop.id}';
          currentProximityKeys.add(key);

          if (!_recentlyNotifiedStopIds.contains(key)) {
            newProximity[shuttle.id] = stop;
            _recentlyNotifiedStopIds.add(key);
          }
        }
      }
    }

    // Remove keys for shuttles that have left a stop's geofence
    _recentlyNotifiedStopIds.removeWhere(
      (key) => !currentProximityKeys.contains(key),
    );

    emit(TrackingActive(
      shuttles: event.shuttles,
      activeRoute: event.route,
      shuttleStopProximity: newProximity,
    ));
  }

  @override
  Future<void> close() async {
    await _shuttleSubscription?.cancel();
    _shuttleRepository.stopSimulation();
    return super.close();
  }
}
