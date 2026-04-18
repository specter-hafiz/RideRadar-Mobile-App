import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<UpdateGeofenceRadius>(_onUpdateGeofenceRadius);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<UpdateSelectedRoute>(_onUpdateSelectedRoute);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final notificationsEnabled =
        await _settingsRepository.getNotificationsEnabled();
    final geofenceRadius = await _settingsRepository.getGeofenceRadius();
    final onboardingCompleted =
        await _settingsRepository.getOnboardingCompleted();
    final selectedRouteId = await _settingsRepository.getSelectedRouteId();

    emit(SettingsLoaded(
      notificationsEnabled: notificationsEnabled,
      geofenceRadius: geofenceRadius,
      onboardingCompleted: onboardingCompleted,
      selectedRouteId: selectedRouteId,
    ));
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final toggled = !currentState.notificationsEnabled;
      await _settingsRepository.setNotificationsEnabled(toggled);
      emit(SettingsLoaded(
        notificationsEnabled: toggled,
        geofenceRadius: currentState.geofenceRadius,
        onboardingCompleted: currentState.onboardingCompleted,
        selectedRouteId: currentState.selectedRouteId,
      ));
    }
  }

  Future<void> _onUpdateGeofenceRadius(
    UpdateGeofenceRadius event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      await _settingsRepository.setGeofenceRadius(event.meters);
      emit(SettingsLoaded(
        notificationsEnabled: currentState.notificationsEnabled,
        geofenceRadius: event.meters,
        onboardingCompleted: currentState.onboardingCompleted,
        selectedRouteId: currentState.selectedRouteId,
      ));
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      await _settingsRepository.setOnboardingCompleted(true);
      emit(SettingsLoaded(
        notificationsEnabled: currentState.notificationsEnabled,
        geofenceRadius: currentState.geofenceRadius,
        onboardingCompleted: true,
        selectedRouteId: currentState.selectedRouteId,
      ));
    }
  }

  Future<void> _onUpdateSelectedRoute(
    UpdateSelectedRoute event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      await _settingsRepository.setSelectedRouteId(event.routeId);
      emit(SettingsLoaded(
        notificationsEnabled: currentState.notificationsEnabled,
        geofenceRadius: currentState.geofenceRadius,
        onboardingCompleted: currentState.onboardingCompleted,
        selectedRouteId: event.routeId,
      ));
    }
  }
}
