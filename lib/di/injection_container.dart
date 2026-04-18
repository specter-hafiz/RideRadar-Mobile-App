import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/data/datasources/local_settings_datasource.dart';
import 'package:shuttletrack/data/datasources/mock_tracking_datasource.dart';
import 'package:shuttletrack/data/repositories/route_repository_impl.dart';
import 'package:shuttletrack/data/repositories/settings_repository_impl.dart';
import 'package:shuttletrack/data/repositories/shuttle_repository_impl.dart';
import 'package:shuttletrack/domain/repositories/route_repository.dart';
import 'package:shuttletrack/domain/repositories/settings_repository.dart';
import 'package:shuttletrack/domain/repositories/shuttle_repository.dart';
import 'package:shuttletrack/presentation/bloc/alert/alert_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/bloc/settings/settings_bloc.dart';
import 'package:shuttletrack/presentation/bloc/tracking/tracking_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  // Datasources
  sl.registerLazySingleton(() => MockTrackingDatasource());
  sl.registerLazySingleton(
    () => LocalSettingsDatasource(sl<SharedPreferences>()),
  );

  // Repositories
  sl.registerLazySingleton<ShuttleRepository>(
    () => ShuttleRepositoryImpl(sl<MockTrackingDatasource>()),
  );
  sl.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(sl<MockTrackingDatasource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<LocalSettingsDatasource>()),
  );

  // Services
  sl.registerLazySingleton(() => NotificationService());

  // BLoCs — registered as singletons since they hold global app state
  sl.registerLazySingleton(
    () => TrackingBloc(
      shuttleRepository: sl<ShuttleRepository>(),
      routeRepository: sl<RouteRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => RouteBloc(routeRepository: sl<RouteRepository>()),
  );
  sl.registerLazySingleton(() => AlertBloc());
  sl.registerLazySingleton(
    () => SettingsBloc(settingsRepository: sl<SettingsRepository>()),
  );
}
