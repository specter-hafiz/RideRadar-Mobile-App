part of 'route_bloc.dart';

sealed class RouteState extends Equatable {
  const RouteState();
  @override
  List<Object?> get props => [];
}

final class RouteInitial extends RouteState {
  const RouteInitial();
}

final class RouteLoading extends RouteState {
  const RouteLoading();
}

final class RouteEmpty extends RouteState {
  const RouteEmpty();
}

final class RouteLoaded extends RouteState {
  final List<ShuttleRoute> routes;
  final ShuttleRoute? selectedRoute;

  const RouteLoaded({required this.routes, this.selectedRoute});

  @override
  List<Object?> get props => [routes, selectedRoute];
}

final class RouteError extends RouteState {
  final String message;
  const RouteError(this.message);
  @override
  List<Object?> get props => [message];
}
