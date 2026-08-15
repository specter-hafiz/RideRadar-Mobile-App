import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/widgets/app_backdrop.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.directions_bus_rounded,
      title: 'Track Your Shuttle',
      subtitle: 'See exactly where your campus shuttle is in real time.',
    ),
    _OnboardingPageData(
      icon: Icons.route_rounded,
      title: 'Choose Your Route',
      subtitle: 'Select from available shuttle routes to monitor.',
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_rounded,
      title: 'Never Miss Your Stop',
      subtitle: 'Get notified when the shuttle approaches your stop.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onNext() {
    if (_isLastPage) {
      // Fire the event — _AppEntry's BlocBuilder will react to the new state:
      // onboardingCompleted=true & userRefNumber=null → LoginScreen.
      // No manual navigation needed here.
      context.read<SettingsBloc>().add(const CompleteOnboarding());
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  rs(context, 20),
                  rs(context, 20),
                  rs(context, 20),
                  0,
                ),
                child: _BrandHeader(theme: theme),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _OnboardingPage(data: _pages[index]),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  rs(context, 20),
                  0,
                  rs(context, 20),
                  rs(context, 24),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs(context, 18),
                    vertical: rs(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: _pages.length,
                            effect: ExpandingDotsEffect(
                              activeDotColor: theme.colorScheme.primary,
                              dotColor: theme.colorScheme.outlineVariant,
                              dotHeight: rs(context, 10),
                              dotWidth: rs(context, 10),
                              expansionFactor: 3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: rs(context, 8)),
                      FilledButton.icon(
                        onPressed: _onNext,
                        icon: Icon(
                          _isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(_isLastPage ? 'Get Started' : 'Next'),
                      ),
                    ],
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

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rs(context, 24)),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rw(context, 420)),
            child: Container(
              padding: EdgeInsets.all(rs(context, 28)),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: rs(context, 112),
                    height: rs(context, 112),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      size: rs(context, 56),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: rs(context, 36)),
                  Text(
                    data.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: rs(context, 16)),
                  Text(
                    data.subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final ThemeData theme;

  const _BrandHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: rs(context, 48),
          height: rs(context, 48),
          padding: EdgeInsets.all(rs(context, 8)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            shape: BoxShape.circle,
          ),
          child: Image.asset('assets/icons/logo.png'),
        ),
        SizedBox(width: rs(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RideRadar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Welcome aboard',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
