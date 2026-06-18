// Widget test for app startup.
//
// The app binds to live Firebase services (Realtime Database / Firestore) the
// moment its blocs are constructed, so the Firebase core platform channel is
// mocked here to let the widget tree build without a real Firebase project.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttletrack/app.dart';
import 'package:shuttletrack/di/injection_container.dart';

class _MockFirebaseCore {
  static void setUp() {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('plugins.flutter.io/firebase_core');
    const app = <String, dynamic>{
      'name': '[DEFAULT]',
      'options': <String, dynamic>{
        'apiKey': 'test',
        'appId': 'test',
        'messagingSenderId': 'test',
        'projectId': 'test',
      },
      'pluginConstants': <String, dynamic>{},
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return <Map<String, dynamic>>[app];
        case 'Firebase#initializeApp':
          return app;
        default:
          return null;
      }
    });
  }
}

void main() {
  setUp(() async {
    _MockFirebaseCore.setUp();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App boots past the splash to onboarding without hanging', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RideRadarApp());

    // Let the (mocked) settings load so we leave the startup splash.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Fresh install -> onboarding is the first real screen after the splash.
    expect(find.text('Track Your Shuttle'), findsOneWidget);
  });
}
