import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/domain/entities/shuttle_alert.dart';
import 'package:shuttletrack/presentation/bloc/alert/alert_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:shuttletrack/presentation/screens/alerts_screen.dart';
import 'package:shuttletrack/presentation/screens/home_screen.dart';
import 'package:shuttletrack/presentation/screens/routes_screen.dart';
import 'package:shuttletrack/presentation/screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // When a route is selected from the Routes tab, switch to Home
        BlocListener<RouteBloc, RouteState>(
          listenWhen: (previous, current) {
            if (previous is RouteLoaded && current is RouteLoaded) {
              return previous.selectedRoute != current.selectedRoute &&
                  current.selectedRoute != null;
            }
            return false;
          },
          listener: (context, state) => _switchToTab(0),
        ),
        // Cross-bloc: tracking proximity triggers alerts & notifications
        BlocListener<TrackingBloc, TrackingState>(
          listener: (context, state) {
            if (state is! TrackingActive) return;
            if (state.shuttleStopProximity.isEmpty) return;

            final settingsState = context.read<SettingsBloc>().state;
            final notificationsEnabled =
                settingsState is SettingsLoaded &&
                settingsState.notificationsEnabled;

            for (final entry in state.shuttleStopProximity.entries) {
              final shuttle = state.shuttles.firstWhere(
                (s) => s.id == entry.key,
              );
              final stop = entry.value;

              final alert = ShuttleAlert(
                id:
                    '${shuttle.id}_${stop.id}_'
                    '${DateTime.now().millisecondsSinceEpoch}',
                shuttleName: shuttle.name,
                stopName: stop.name,
                routeName: state.activeRoute.name,
                message: '${shuttle.name} approaching ${stop.name}',
                timestamp: DateTime.now(),
              );

              context.read<AlertBloc>().add(AddAlert(alert));

              if (notificationsEnabled) {
                sl<NotificationService>().showStopAlert(
                  shuttleName: shuttle.name,
                  stopName: stop.name,
                  routeName: state.activeRoute.name,
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(onSelectRoute: () => _switchToTab(1)),
            const RoutesScreen(),
            const AlertsScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBar(
                selectedIndex: _currentIndex,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onDestinationSelected: _switchToTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined),
                    selectedIcon: Icon(Icons.route_rounded),
                    label: 'Routes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications_rounded),
                    label: 'Alerts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
