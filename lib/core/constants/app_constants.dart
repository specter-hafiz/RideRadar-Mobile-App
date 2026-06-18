class AppConstants {
  AppConstants._();

  static const String appName = 'RideRadar';
  static const double defaultGeofenceRadiusMeters = 100.0;
  static const Duration simulationTickInterval = Duration(seconds: 3);
  static const double defaultMapZoom = 15.0;

  // SharedPreferences keys
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyGeofenceRadius = 'geofence_radius';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keySelectedRouteId = 'selected_route_id';
  static const String keyUserRefNumber = 'user_ref_number';
}
