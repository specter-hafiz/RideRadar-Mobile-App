import 'package:shuttletrack/data/datasources/local_settings_datasource.dart';
import 'package:shuttletrack/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalSettingsDatasource _datasource;

  const SettingsRepositoryImpl(this._datasource);

  @override
  Future<bool> getNotificationsEnabled() async =>
      _datasource.getNotificationsEnabled();

  @override
  Future<void> setNotificationsEnabled(bool enabled) =>
      _datasource.setNotificationsEnabled(enabled);

  @override
  Future<double> getGeofenceRadius() async =>
      _datasource.getGeofenceRadius();

  @override
  Future<void> setGeofenceRadius(double meters) =>
      _datasource.setGeofenceRadius(meters);

  @override
  Future<bool> getOnboardingCompleted() async =>
      _datasource.getOnboardingCompleted();

  @override
  Future<void> setOnboardingCompleted(bool completed) =>
      _datasource.setOnboardingCompleted(completed);

  @override
  Future<String?> getSelectedRouteId() async =>
      _datasource.getSelectedRouteId();

  @override
  Future<void> setSelectedRouteId(String? routeId) =>
      _datasource.setSelectedRouteId(routeId);
}
