part of 'route_bloc.dart';

sealed class RouteEvent extends Equatable {
  const RouteEvent();
  @override
  List<Object?> get props => [];
}

final class LoadRoutes extends RouteEvent {
  const LoadRoutes();
}

final class SelectRoute extends RouteEvent {
  final String routeId;
  const SelectRoute(this.routeId);
  @override
  List<Object?> get props => [routeId];
}
