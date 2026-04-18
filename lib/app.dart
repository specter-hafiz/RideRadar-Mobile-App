import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/core/theme/app_theme.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/presentation/bloc/alert/alert_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:shuttletrack/presentation/screens/app_shell.dart';
import 'package:shuttletrack/presentation/screens/onboarding_screen.dart';

class ShuttleTrackApp extends StatelessWidget {
  const ShuttleTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<TrackingBloc>()),
        BlocProvider.value(value: sl<RouteBloc>()..add(const LoadRoutes())),
        BlocProvider.value(value: sl<AlertBloc>()),
        BlocProvider.value(
          value: sl<SettingsBloc>()..add(const LoadSettings()),
        ),
      ],
      child: MaterialApp(
        title: 'ShuttleTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoaded && state.onboardingCompleted) {
              return const AppShell();
            }
            if (state is SettingsLoaded) {
              return const OnboardingScreen();
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
