part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

final class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

final class ToggleNotifications extends SettingsEvent {
  const ToggleNotifications();
}

final class UpdateGeofenceRadius extends SettingsEvent {
  final double meters;
  const UpdateGeofenceRadius(this.meters);
  @override
  List<Object?> get props => [meters];
}

final class CompleteOnboarding extends SettingsEvent {
  const CompleteOnboarding();
}

final class UpdateSelectedRoute extends SettingsEvent {
  final String? routeId;
  const UpdateSelectedRoute(this.routeId);
  @override
  List<Object?> get props => [routeId];
}

final class SetUserRefNumber extends SettingsEvent {
  final String refNumber;
  const SetUserRefNumber(this.refNumber);
  @override
  List<Object?> get props => [refNumber];
}

final class ClearUserRefNumber extends SettingsEvent {
  const ClearUserRefNumber();
}
