part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

final class SettingsLoaded extends SettingsState {
  final bool notificationsEnabled;
  final double geofenceRadius;
  final bool onboardingCompleted;
  final String? selectedRouteId;
  final String? userRefNumber;

  const SettingsLoaded({
    required this.notificationsEnabled,
    required this.geofenceRadius,
    required this.onboardingCompleted,
    this.selectedRouteId,
    this.userRefNumber,
  });

  @override
  List<Object?> get props => [
        notificationsEnabled,
        geofenceRadius,
        onboardingCompleted,
        selectedRouteId,
        userRefNumber,
      ];
}
