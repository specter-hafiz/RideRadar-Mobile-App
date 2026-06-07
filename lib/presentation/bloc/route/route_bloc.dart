import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/domain/repositories/route_repository.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteRepository _routeRepository;

  RouteBloc({required RouteRepository routeRepository})
    : _routeRepository = routeRepository,
      super(const RouteInitial()) {
    on<LoadRoutes>(_onLoadRoutes);
    on<SelectRoute>(_onSelectRoute);
  }

  Future<void> _onLoadRoutes(LoadRoutes event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());

    try {
      final previousSelectionId = state is RouteLoaded
          ? (state as RouteLoaded).selectedRoute?.id
          : null;
      final routes = await _routeRepository.getRoutes();
      if (routes.isEmpty) {
        emit(const RouteEmpty());
        return;
      }

      ShuttleRoute? selectedRoute;
      if (previousSelectionId != null) {
        for (final route in routes) {
          if (route.id == previousSelectionId) {
            selectedRoute = route;
            break;
          }
        }
      }

      emit(RouteLoaded(routes: routes, selectedRoute: selectedRoute));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  void _onSelectRoute(SelectRoute event, Emitter<RouteState> emit) {
    final currentState = state;
    if (currentState is RouteLoaded) {
      final selectedRoute = currentState.routes.firstWhere(
        (route) => route.id == event.routeId,
      );
      emit(
        RouteLoaded(routes: currentState.routes, selectedRoute: selectedRoute),
      );
    }
  }
}
