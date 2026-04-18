part of 'tracking_bloc.dart';

sealed class TrackingState extends Equatable {
  const TrackingState();
  @override
  List<Object?> get props => [];
}

final class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

final class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

final class TrackingActive extends TrackingState {
  final List<Shuttle> shuttles;
  final ShuttleRoute activeRoute;

  /// Maps shuttleId to the BusStop it's currently near (within geofence radius).
  /// Only contains NEW proximity entries not yet notified, so the UI's
  /// BlocListener can trigger notifications only for new arrivals.
  final Map<String, BusStop> shuttleStopProximity;

  const TrackingActive({
    required this.shuttles,
    required this.activeRoute,
    this.shuttleStopProximity = const {},
  });

  @override
  List<Object?> get props => [shuttles, activeRoute, shuttleStopProximity];
}

final class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
  @override
  List<Object?> get props => [message];
}
