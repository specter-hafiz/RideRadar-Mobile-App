import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/core/theme/app_theme.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/presentation/bloc/alert/alert_bloc.dart';
import 'package:shuttletrack/presentation/bloc/network/network_cubit.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:shuttletrack/presentation/screens/app_shell.dart';
import 'package:shuttletrack/presentation/screens/login_screen.dart';
import 'package:shuttletrack/presentation/screens/onboarding_screen.dart';

class RideRadarApp extends StatelessWidget {
  const RideRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<TrackingBloc>()),
        BlocProvider.value(value: sl<RouteBloc>()..add(const LoadRoutes())),
        BlocProvider.value(value: sl<AlertBloc>()),
        BlocProvider.value(value: sl<NetworkCubit>()),
        BlocProvider.value(
          value: sl<SettingsBloc>()..add(const LoadSettings()),
        ),
      ],
      child: MaterialApp(
        title: 'RideRadar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded) {
          if (!state.onboardingCompleted) return const OnboardingScreen();
          if (state.userRefNumber == null) return const LoginScreen();
          return const AppShell();
        }

        return const Scaffold(body: StartupLoadingView());
      },
    );
  }
}

/// The branded loading view shown on startup while settings load.
class StartupLoadingView extends StatefulWidget {
  const StartupLoadingView({super.key});

  @override
  State<StartupLoadingView> createState() => _StartupLoadingViewState();
}

class _StartupLoadingViewState extends State<StartupLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? const [Color(0xFF06100C), Color(0xFF0D1712), Color(0xFF09130E)]
              : const [Color(0xFFFDFDFB), Color(0xFFEAF4EC), Color(0xFFF6FAF6)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final pulse =
                      0.94 + (math.sin(_controller.value * math.pi * 2) * 0.03);
                  return Transform.scale(scale: pulse, child: child);
                },
                child: Container(
                  width: 180,
                  height: 180,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.16),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _StartupRadarPainter(
                          progress: _controller.value,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/logo.png',
                            width: 78,
                            height: 78,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'RideRadar',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Syncing routes and live shuttle data...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupRadarPainter extends CustomPainter {
  final double progress;

  const _StartupRadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05;

    for (var index = 0; index < 4; index++) {
      final radius = size.shortestSide * (0.17 + index * 0.16);
      basePaint.color = const Color(
        0xFF9AA7A0,
      ).withValues(alpha: index == 3 ? 0.15 : 0.22);
      canvas.drawCircle(center, radius, basePaint);
    }

    final angle = progress * math.pi * 2;
    final sweepEnd =
        center +
        Offset(math.cos(angle), math.sin(angle)) * (size.shortestSide * 0.36);

    final sweepPaint = Paint()
      ..color = const Color(0xFF14532D).withValues(alpha: 0.18)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, sweepEnd, sweepPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFF2B544).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.shortestSide * 0.014, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _StartupRadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
