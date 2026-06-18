abstract class SettingsRepository {
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<double> getGeofenceRadius();
  Future<void> setGeofenceRadius(double meters);
  Future<bool> getOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  Future<String?> getSelectedRouteId();
  Future<void> setSelectedRouteId(String? routeId);
  Future<String?> getUserRefNumber();
  Future<void> setUserRefNumber(String refNumber);
  Future<void> clearUserRefNumber();
}
