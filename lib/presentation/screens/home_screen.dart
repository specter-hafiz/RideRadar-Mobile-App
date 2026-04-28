import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:shuttletrack/presentation/widgets/shuttle_info_card.dart';
import 'package:shuttletrack/presentation/widgets/shuttle_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RouteBloc, RouteState>(
      listenWhen: (previous, current) {
        if (previous is RouteLoaded && current is RouteLoaded) {
          return previous.selectedRoute?.id != current.selectedRoute?.id;
        }
        return current is RouteLoaded && current.selectedRoute != null;
      },
      listener: (context, state) {
        if (state is RouteLoaded && state.selectedRoute != null) {
          context.read<TrackingBloc>().add(
            StartTracking(state.selectedRoute!.id),
          );
        }
      },
      child: BlocBuilder<RouteBloc, RouteState>(
        builder: (context, routeState) {
          final selectedRoute = routeState is RouteLoaded
              ? routeState.selectedRoute
              : null;

          return BlocBuilder<TrackingBloc, TrackingState>(
            builder: (context, trackingState) {
              final shuttles = trackingState is TrackingActive
                  ? trackingState.shuttles
                  : <dynamic>[];
              final activeRoute = trackingState is TrackingActive
                  ? trackingState.activeRoute
                  : selectedRoute;
              return Stack(
                children: [
                  ShuttleMap(
                    route: trackingState is TrackingActive
                        ? trackingState.activeRoute
                        : null,
                    shuttles: trackingState is TrackingActive
                        ? trackingState.shuttles
                        : const [],
                  ),

                  if (trackingState is TrackingLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (selectedRoute == null &&
                      trackingState is! TrackingLoading)
                    _NoRoutePrompt(),

                  if (activeRoute != null && shuttles.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: ShuttleInfoCard(
                        route: activeRoute,
                        shuttles: trackingState is TrackingActive
                            ? trackingState.shuttles
                            : const [],
                        proximityMap: trackingState is TrackingActive
                            ? trackingState.shuttleStopProximity
                            : const {},
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NoRoutePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a Route',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a route from the Routes tab to start tracking shuttles.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
