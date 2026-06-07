import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/widgets/app_backdrop.dart';
import 'package:shuttletrack/presentation/widgets/route_card.dart';

Future<void> _refreshRoutes(BuildContext context) async {
  final routeBloc = context.read<RouteBloc>();
  routeBloc.add(const LoadRoutes());

  await routeBloc.stream.firstWhere(
    (state) =>
        state is RouteLoaded || state is RouteEmpty || state is RouteError,
  );
}

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Routes'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: AppBackdrop(
        child: BlocBuilder<RouteBloc, RouteState>(
          builder: (context, state) {
            final child = switch (state) {
              RouteLoading() => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 260),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
              RouteError(:final message) => _RouteErrorView(
                message: message,
                onRetry: () => _refreshRoutes(context),
              ),
              RouteEmpty() => _RouteEmptyView(
                onRetry: () => _refreshRoutes(context),
              ),
              RouteLoaded(:final routes, :final selectedRoute) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _RoutesHero(
                    routeCount: routes.length,
                    selectedRoute: selectedRoute?.name,
                  ),
                  const SizedBox(height: 16),
                  ...routes.map(
                    (route) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RouteCard(
                        route: route,
                        isSelected: selectedRoute?.id == route.id,
                        onTap: () {
                          context.read<RouteBloc>().add(SelectRoute(route.id));
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            };

            return RefreshIndicator(
              onRefresh: () => _refreshRoutes(context),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _RouteErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _RouteErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 72),
        Icon(Icons.cloud_off_rounded, size: 52, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Could not load routes',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => onRetry(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _RouteEmptyView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _RouteEmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 72),
        Icon(Icons.route_outlined, size: 52, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'No routes available',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh once your Firestore routes are ready.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => onRetry(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _RoutesHero extends StatelessWidget {
  final int routeCount;
  final String? selectedRoute;

  const _RoutesHero({required this.routeCount, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a route',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a shuttle route to start live tracking and proximity alerts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.route_rounded,
                label: '$routeCount routes available',
              ),
              if (selectedRoute != null)
                _InfoChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Selected: $selectedRoute',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
