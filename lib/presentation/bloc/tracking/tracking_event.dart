part of 'tracking_bloc.dart';

sealed class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object?> get props => [];
}

final class StartTracking extends TrackingEvent {
  final String routeId;
  const StartTracking(this.routeId);
  @override
  List<Object?> get props => [routeId];
}

final class StopTracking extends TrackingEvent {
  const StopTracking();
}

final class _ShuttlePositionsUpdated extends TrackingEvent {
  final List<Shuttle> shuttles;
  final ShuttleRoute route;
  const _ShuttlePositionsUpdated({
    required this.shuttles,
    required this.route,
  });
  @override
  List<Object?> get props => [shuttles, route];
}
