import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/presentation/bloc/network/network_cubit.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:shuttletrack/presentation/widgets/app_backdrop.dart';
import 'package:shuttletrack/presentation/widgets/shuttle_map.dart';

Future<void> _refreshHome(BuildContext context) async {
  final routeBloc = context.read<RouteBloc>();
  final trackingBloc = context.read<TrackingBloc>();

  final selectedRouteId = routeBloc.state is RouteLoaded
      ? (routeBloc.state as RouteLoaded).selectedRoute?.id
      : null;

  routeBloc.add(const LoadRoutes());
  final refreshedState = await routeBloc.stream.firstWhere(
    (state) =>
        state is RouteLoaded || state is RouteEmpty || state is RouteError,
  );

  if (refreshedState is RouteLoaded) {
    final routeId = refreshedState.selectedRoute?.id ?? selectedRouteId;
    if (routeId != null) {
      trackingBloc.add(StartTracking(routeId));
      await trackingBloc.stream.firstWhere(
        (state) => state is TrackingActive || state is TrackingError,
      );
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (previous, current) =>
          previous.isConnected != current.isConnected,
      listener: (context, state) {
        if (!state.isConnected) return;
        final routeState = context.read<RouteBloc>().state;
        if (routeState is RouteLoaded && routeState.selectedRoute != null) {
          _refreshHome(context);
        }
      },
      child: BlocListener<RouteBloc, RouteState>(
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
                final activeRoute = trackingState is TrackingActive
                    ? trackingState.activeRoute
                    : selectedRoute;
                final networkState = context.watch<NetworkCubit>().state;

                return AppBackdrop(
                  child: Stack(
                    children: [
                      // ── Map Layer ──────────────────────────────────
                      Positioned.fill(
                        child: ShuttleMap(
                          route: trackingState is TrackingActive
                              ? trackingState.activeRoute
                              : null,
                          shuttles: trackingState is TrackingActive
                              ? trackingState.shuttles
                              : const [],
                        ),
                      ),

                      // ── Top HUD ────────────────────────────────────
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FloatingHeaderCard(
                                  routeLabel: activeRoute?.name,
                                  isConnected: networkState.isConnected,
                                ),
                                const SizedBox(height: 10),
                                // Status banners (at most one shown)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, -0.15),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      ),
                                  child: _resolveBanner(
                                    context,
                                    routeState,
                                    trackingState,
                                    networkState,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── No Route Overlay ───────────────────────────
                      if (selectedRoute == null &&
                          routeState is! RouteLoading &&
                          routeState is! RouteError)
                        _NoRoutePrompt(
                          onRefresh: () => _refreshHome(context),
                        ),

                      // ── Bottom Route Panel ─────────────────────────
                      if (activeRoute != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: SafeArea(
                            top: false,
                            child: _FloatingRoutePanel(
                              route: activeRoute,
                              shuttles: trackingState is TrackingActive
                                  ? trackingState.shuttles
                                  : const [],
                              proximityMap: trackingState is TrackingActive
                                  ? trackingState.shuttleStopProximity
                                  : const {},
                              isLive: trackingState is TrackingActive,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Returns the single highest-priority status banner, or an empty
  /// [SizedBox] (keyed so [AnimatedSwitcher] can fade it out cleanly).
  Widget _resolveBanner(
    BuildContext context,
    RouteState routeState,
    TrackingState trackingState,
    NetworkState networkState,
  ) {
    if (routeState is RouteError) {
      return _StatusBanner(
        key: const ValueKey('route_error'),
        icon: Icons.cloud_off_rounded,
        title: 'Route data unavailable',
        message: routeState.message,
        actionLabel: 'Retry',
        onAction: () => _refreshHome(context),
        severity: _BannerSeverity.error,
      );
    }
    if (trackingState is TrackingError) {
      return _StatusBanner(
        key: const ValueKey('tracking_error'),
        icon: Icons.wifi_off_rounded,
        title: 'Live tracking paused',
        message: trackingState.message,
        actionLabel: 'Retry',
        onAction: () => _refreshHome(context),
        severity: _BannerSeverity.warning,
      );
    }
    if (!networkState.isConnected) {
      return _StatusBanner(
        key: const ValueKey('offline'),
        icon: Icons.signal_wifi_off_rounded,
        title: 'You\'re offline',
        message: 'Reconnect to resume live shuttle updates.',
        actionLabel: 'Refresh',
        onAction: () => _refreshHome(context),
        severity: _BannerSeverity.warning,
      );
    }
    if (trackingState is TrackingLoading) {
      return const _LoadingBanner(key: ValueKey('loading'));
    }
    return const SizedBox.shrink(key: ValueKey('none'));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingHeaderCard extends StatelessWidget {
  final String? routeLabel;
  final bool isConnected;

  const _FloatingHeaderCard({
    required this.routeLabel,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _BrandBadge(),
          const Spacer(),
          if (routeLabel != null) _RouteChip(label: routeLabel!),
          const SizedBox(width: 10),
          _LiveDot(isConnected: isConnected),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  final String label;

  const _RouteChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated live indicator dot
// ─────────────────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final bool isConnected;

  const _LiveDot({required this.isConnected});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scale = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isConnected
        ? const Color(0xFF22C55E)
        : theme.colorScheme.error;

    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isConnected)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: _opacity.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner (error / warning / info)
// ─────────────────────────────────────────────────────────────────────────────

enum _BannerSeverity { error, warning, info }

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final _BannerSeverity severity;

  const _StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (iconBg, iconFg) = switch (severity) {
      _BannerSeverity.error => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      _BannerSeverity.warning => (
        const Color(0xFFFFF3CD),
        const Color(0xFF7C5800),
      ),
      _BannerSeverity.info => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading Banner
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBanner extends StatefulWidget {
  const _LoadingBanner({super.key});

  @override
  State<_LoadingBanner> createState() => _LoadingBannerState();
}

class _LoadingBannerState extends State<_LoadingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-2 + _shimmer.value * 4, 0),
                  end: Alignment(-1 + _shimmer.value * 4, 0),
                ).createShader(bounds),
                child: Text(
                  'Updating shuttle positions…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Route Panel (bottom card)
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingRoutePanel extends StatelessWidget {
  final ShuttleRoute route;
  final List<Shuttle> shuttles;
  final Map<String, BusStop> proximityMap;
  final bool isLive;

  const _FloatingRoutePanel({
    required this.route,
    required this.shuttles,
    required this.proximityMap,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeShuttles = shuttles.where((s) => s.isActive).toList();
    final routeColor = Color(int.parse(route.colorHex, radix: 16));

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Coloured route accent line ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: routeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 2,
                      width: 32,
                      decoration: BoxDecoration(
                        color: routeColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Route name row ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                route.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ShuttleCountBadge(
                          count: activeShuttles.length,
                          isLive: isLive,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Stop strip ──
                    _StopStrip(
                      stops: route.stops,
                      proximityMap: proximityMap,
                      routeColor: routeColor,
                    ),
                    // ── Footer status ──
                    if (proximityMap.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ProximityRow(proximityMap: proximityMap),
                    ] else if (activeShuttles.isEmpty && isLive) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Waiting for device signal…',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuttleCountBadge extends StatelessWidget {
  final int count;
  final bool isLive;

  const _ShuttleCountBadge({required this.count, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasShuttles = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasShuttles
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive && hasShuttles) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Icon(
            Icons.directions_bus_rounded,
            size: 13,
            color: hasShuttles
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: hasShuttles
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable stop strip — shows all stops in order with connectors.
class _StopStrip extends StatelessWidget {
  final List<BusStop> stops;
  final Map<String, BusStop> proximityMap;
  final Color routeColor;

  const _StopStrip({
    required this.stops,
    required this.proximityMap,
    required this.routeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < stops.length; i++) ...[
            _StopNode(
              stop: stops[i],
              isFirst: i == 0,
              isLast: i == stops.length - 1,
              isNearby: proximityMap.containsKey(stops[i].id),
              routeColor: routeColor,
            ),
            if (i < stops.length - 1) _StopConnector(routeColor: routeColor),
          ],
        ],
      ),
    );
  }
}

class _StopNode extends StatelessWidget {
  final BusStop stop;
  final bool isFirst;
  final bool isLast;
  final bool isNearby;
  final Color routeColor;

  const _StopNode({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.isNearby,
    required this.routeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isNearby
                ? routeColor
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isFirst || isLast
                  ? routeColor
                  : theme.colorScheme.outlineVariant,
              width: isFirst || isLast ? 2.5 : 1.5,
            ),
            boxShadow: isNearby
                ? [
                    BoxShadow(
                      color: routeColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isNearby ? Icons.location_on_rounded : Icons.circle,
              size: isNearby ? 14 : 8,
              color: isNearby
                  ? Colors.white
                  : (isFirst || isLast
                        ? routeColor
                        : theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 72,
          child: Text(
            stop.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              height: 1.2,
              fontWeight: isNearby ? FontWeight.w700 : FontWeight.w500,
              color: isNearby
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StopConnector extends StatelessWidget {
  final Color routeColor;

  const _StopConnector({required this.routeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: 24,
        height: 2,
        child: CustomPaint(
          painter: _DashedLinePainter(color: routeColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _ProximityRow extends StatelessWidget {
  final Map<String, BusStop> proximityMap;

  const _ProximityRow({required this.proximityMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = proximityMap.values.map((s) => s.name).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, size: 14, color: Color(0xFF22C55E)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Nearby: $names',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF16A34A),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Route Prompt
// ─────────────────────────────────────────────────────────────────────────────

class _NoRoutePrompt extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NoRoutePrompt({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: 34,
                      height: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Select a Route',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a route from the Routes tab to start live tracking and proximity alerts.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => onRefresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh Routes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Badge
// ─────────────────────────────────────────────────────────────────────────────

class _BrandBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('assets/icons/logo.png'),
        ),
        const SizedBox(width: 8),
        Text(
          'RideRadar',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
