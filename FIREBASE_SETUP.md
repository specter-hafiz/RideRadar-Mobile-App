# Firebase & Services Setup Guide

This guide covers how to transition ShuttleTrack from mock data to a live Firebase backend, configure Google Maps, set up push notifications, and integrate AdMob.

---

## 1. Firebase Project Setup

### Create a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project (e.g., `shuttletrack`).
2. Enable **Cloud Firestore** under Build > Firestore Database (start in test mode, then apply rules below).
3. Enable **Cloud Messaging** under Build > Cloud Messaging.

### Connect Flutter to Firebase

```bash
# Install the FlutterFire CLI
dart pub global activate flutterfire_cli

# From the project root, run:
flutterfire configure
```

This generates `lib/firebase_options.dart` with platform-specific config.

### Enable dependencies

In `pubspec.yaml`, uncomment the Firebase dependencies:

```yaml
firebase_core: ^3.12.1
cloud_firestore: ^5.6.7
firebase_messaging: ^15.2.4
```

Then run `flutter pub get`.

### Initialize Firebase in `main.dart`

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  await sl<NotificationService>().initialize();
  runApp(const ShuttleTrackApp());
}
```

---

## 2. Firestore Data Model

### `/shuttles/{shuttleId}`

| Field         | Type      | Description                          |
|---------------|-----------|--------------------------------------|
| name          | string    | Display name (e.g., "Shuttle A")     |
| routeId       | string    | ID of the route this shuttle runs on |
| location      | GeoPoint  | Current GPS coordinates              |
| heading       | number    | Compass bearing in degrees           |
| speed         | number    | Speed in m/s                         |
| isActive      | boolean   | Whether the shuttle is in service    |
| lastUpdated   | timestamp | Last position update time            |

### `/routes/{routeId}`

| Field                | Type            | Description                             |
|----------------------|-----------------|-----------------------------------------|
| name                 | string          | Route display name                      |
| description          | string          | Short description                       |
| colorHex             | string          | Hex color code (e.g., `FF14532D`)       |
| polylineCoordinates  | array<GeoPoint> | Ordered list of points forming the path |
| isActive             | boolean         | Whether the route is currently active   |

### `/stops/{stopId}`

| Field   | Type     | Description                    |
|---------|----------|--------------------------------|
| name    | string   | Stop display name              |
| location| GeoPoint | GPS coordinates                |
| order   | number   | Stop sequence on the route     |
| routeId | string   | ID of the parent route         |

---

## 3. Dynamic Scalability

The Firestore model makes the system automatically scalable:

- **Adding a new shuttle**: Create a new document in `/shuttles`. The app listens to the collection in real time via `snapshots()`, so it discovers new shuttles instantly — no code changes needed.
- **Adding a new route**: Create a document in `/routes` and corresponding documents in `/stops`. The Routes screen auto-populates from the `getRoutes()` query.
- **Taking a shuttle offline**: Set `isActive: false` on the shuttle document. The app filters inactive shuttles from the map.

No redeployment is needed for fleet changes. Everything is driven by Firestore data.

---

## 4. Switching from Mock to Firebase

Create a new datasource to replace `MockTrackingDatasource`:

```dart
// lib/data/datasources/firestore_shuttle_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class FirestoreShuttleDatasource {
  final FirebaseFirestore _firestore;

  FirestoreShuttleDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Shuttle>> watchShuttlesOnRoute(String routeId) {
    return _firestore
        .collection('shuttles')
        .where('routeId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final location = data['location'] as GeoPoint;
              return Shuttle(
                id: doc.id,
                name: data['name'] as String,
                routeId: data['routeId'] as String,
                latitude: location.latitude,
                longitude: location.longitude,
                heading: (data['heading'] as num).toDouble(),
                speed: (data['speed'] as num).toDouble(),
                isActive: data['isActive'] as bool,
                lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
              );
            }).toList());
  }

  Future<List<ShuttleRoute>> getRoutes() async {
    final routeSnap = await _firestore
        .collection('routes')
        .where('isActive', isEqualTo: true)
        .get();

    final routes = <ShuttleRoute>[];
    for (final doc in routeSnap.docs) {
      final data = doc.data();
      final stopsSnap = await _firestore
          .collection('stops')
          .where('routeId', isEqualTo: doc.id)
          .orderBy('order')
          .get();

      final stops = stopsSnap.docs.map((stopDoc) {
        final stopData = stopDoc.data();
        final loc = stopData['location'] as GeoPoint;
        return BusStop(
          id: stopDoc.id,
          name: stopData['name'] as String,
          latitude: loc.latitude,
          longitude: loc.longitude,
          order: stopData['order'] as int,
          routeId: doc.id,
        );
      }).toList();

      final polyPoints = (data['polylineCoordinates'] as List)
          .map((gp) => [(gp as GeoPoint).latitude, gp.longitude])
          .toList();

      routes.add(ShuttleRoute(
        id: doc.id,
        name: data['name'] as String,
        description: data['description'] as String,
        colorHex: data['colorHex'] as String,
        stops: stops,
        polylineCoordinates: polyPoints,
        isActive: true,
      ));
    }
    return routes;
  }

  Future<ShuttleRoute?> getRoute(String routeId) async {
    final routes = await getRoutes();
    return routes.where((r) => r.id == routeId).firstOrNull;
  }
}
```

Then update `injection_container.dart` to register `FirestoreShuttleDatasource` instead of `MockTrackingDatasource`, and update `ShuttleRepositoryImpl` / `RouteRepositoryImpl` to accept the new datasource.

---

## 5. Firebase Security Rules

Since there's no user auth in the current version, use restrictive rules that allow public reads but limit writes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Shuttles: anyone can read, only authenticated service accounts can write
    match /shuttles/{shuttleId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.token.admin == true;
    }

    // Routes: anyone can read, only admin can write
    match /routes/{routeId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.token.admin == true;
    }

    // Stops: anyone can read, only admin can write
    match /stops/{stopId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.token.admin == true;
    }
  }
}
```

For the IoT devices updating shuttle positions, create a service account and set a custom claim `admin: true` via the Firebase Admin SDK.

---

## 6. FCM Push Notifications

### Android setup

1. The `flutterfire configure` command should have added `google-services.json` to `android/app/`.
2. No additional Gradle config is needed with the FlutterFire CLI.

### iOS setup

1. Enable Push Notifications capability in Xcode.
2. Upload your APNs key to Firebase Console > Project Settings > Cloud Messaging.

### Request permission and get token

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

final messaging = FirebaseMessaging.instance;
await messaging.requestPermission();
final token = await messaging.getToken();
// Store token in Firestore for the server to target this device.
```

### Handle incoming messages

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show local notification using NotificationService
});

FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
```

---

## 7. Google Maps API Key

### Android

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **Maps SDK for Android**.
3. Create an API key restricted to your app's SHA-1 and package name.
4. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY_HERE"/>
  </application>
</manifest>
```

### iOS

1. Enable **Maps SDK for iOS** in Google Cloud Console.
2. Create an API key restricted to your iOS bundle identifier.
3. Add to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 8. AdMob Integration

### Create an AdMob account

1. Sign up at [AdMob](https://admob.google.com/).
2. Create an app and note the **App ID** and **Banner Ad Unit ID**.

### Enable the dependency

In `pubspec.yaml`, uncomment:

```yaml
google_mobile_ads: ^5.3.0
```

### Configure platform IDs

**Android** — add to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

**iOS** — add to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

### Initialize in `main.dart`

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // ... rest of init
}
```

### Replace the placeholder widget

Update `lib/presentation/widgets/ad_banner_widget.dart` to load a real `BannerAd`:

```dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'YOUR_BANNER_AD_UNIT_ID',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
```
