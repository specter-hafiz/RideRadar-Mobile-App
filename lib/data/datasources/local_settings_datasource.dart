import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttletrack/core/constants/app_constants.dart';

class LocalSettingsDatasource {
  final SharedPreferences _prefs;

  const LocalSettingsDatasource(this._prefs);

  bool getNotificationsEnabled() =>
      _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);

  double getGeofenceRadius() =>
      _prefs.getDouble(AppConstants.keyGeofenceRadius) ??
      AppConstants.defaultGeofenceRadiusMeters;

  Future<void> setGeofenceRadius(double meters) =>
      _prefs.setDouble(AppConstants.keyGeofenceRadius, meters);

  bool getOnboardingCompleted() =>
      _prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool completed) =>
      _prefs.setBool(AppConstants.keyOnboardingCompleted, completed);

  String? getSelectedRouteId() =>
      _prefs.getString(AppConstants.keySelectedRouteId);

  Future<void> setSelectedRouteId(String? routeId) {
    if (routeId == null) {
      return _prefs.remove(AppConstants.keySelectedRouteId);
    }
    return _prefs.setString(AppConstants.keySelectedRouteId, routeId);
  }
}
