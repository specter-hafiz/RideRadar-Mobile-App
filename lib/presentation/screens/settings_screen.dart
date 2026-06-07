import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/core/constants/app_constants.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/screens/onboarding_screen.dart';
import 'package:shuttletrack/presentation/widgets/app_backdrop.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: AppBackdrop(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is! SettingsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                rs(context, 16),
                rs(context, 8),
                rs(context, 16),
                rs(context, 24),
              ),
              children: [
                _SettingsHero(state: state),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Preferences', theme: theme),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_rounded),
                        title: const Text('Notifications'),
                        subtitle: const Text(
                          'Alert when a shuttle nears a stop',
                        ),
                        value: state.notificationsEnabled,
                        onChanged: (_) {
                          context.read<SettingsBloc>().add(
                            const ToggleNotifications(),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.radar_rounded),
                        title: const Text('Geofence Radius'),
                        subtitle: Text(
                          '${state.geofenceRadius.round()} meters',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showGeofenceDialog(context, state),
                      ),
                    ],
                  ),
                ),
                _SectionHeader(title: 'About', theme: theme),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About RideRadar'),
                    subtitle: const Text('v1.0.0'),
                    onTap: () => _showAboutDialog(context),
                  ),
                ),
                _SectionHeader(title: 'Developer', theme: theme),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.replay_rounded),
                    title: const Text('Show Onboarding'),
                    subtitle: const Text('Reset and view the onboarding flow'),
                    onTap: () {
                      context.read<SettingsBloc>().add(
                        const CompleteOnboarding(),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showGeofenceDialog(BuildContext context, SettingsLoaded state) {
    var radius = state.geofenceRadius;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Geofence Radius'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${radius.round()} meters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: radius,
                min: 50,
                max: 500,
                divisions: 18,
                label: '${radius.round()}m',
                onChanged: (value) => setDialogState(() => radius = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('50m', style: Theme.of(context).textTheme.bodySmall),
                    Text('500m', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<SettingsBloc>().add(UpdateGeofenceRadius(radius));
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'v1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icons/logo.png',
          width: rs(context, 44),
          height: rs(context, 44),
        ),
      ),
      children: [
        const Text(
          'RideRadar lets you track campus shuttles in real time, '
          'view routes, and get notified when your shuttle is nearby.',
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final SettingsLoaded state;

  const _SettingsHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(rs(context, 20)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: rs(context, 28),
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Image.asset(
              'assets/icons/logo.png',
              width: rs(context, 28),
              height: rs(context, 28),
            ),
          ),
          SizedBox(width: rs(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tune your ride',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: rs(context, 4)),
                Text(
                  'Notifications: ${state.notificationsEnabled ? 'On' : 'Off'} · Radius: ${state.geofenceRadius.round()}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
