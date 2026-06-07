# Firebase & Services Setup Guide

This guide describes the live tracking split used by ShuttleTrack:

- Firestore stores route metadata and stop geometry.
- Realtime Database stores live shuttle coordinates from the IoT device.

## Firebase Project Setup

1. Create or open your Firebase project.
2. Enable Cloud Firestore.
3. Enable Realtime Database.
4. Run `flutterfire configure` so `lib/firebase_options.dart` matches your project.

## Data Model

### Firestore: `/routes/{routeId}`

Each route document should contain:

| Field | Type | Description |
|---|---|---|
| name | string | Route name |
| description | string | Short route description |
| colorHex | string | Route color, e.g. `FFF57C00` |
| encodedPolyline | string | Encoded route polyline |
| isActive | boolean | Whether the route is visible in the app |
| stops | array<object> | Ordered list of stops with `id`, `name`, `location`, and `order` |

### Realtime Database: `/liveShuttles/{shuttleId}`

Each live shuttle entry should contain:

| Field | Type | Description |
|---|---|---|
| name | string | Shuttle display name |
| routeId | string | Route this shuttle belongs to |
| latitude | number | Current latitude |
| longitude | number | Current longitude |
| heading | number | Bearing in degrees |
| speed | number | Speed in m/s |
| isActive | boolean | Whether the shuttle should appear on the map |
| lastUpdated | number or string | Latest update time |

The Flutter app listens to `liveShuttles` in real time and filters by `routeId`, while route rendering still comes from Firestore.

## App Wiring

The app initializes Firebase in `lib/main.dart`. Keep route loading on Firestore through the route repository, and keep shuttle tracking on RTDB through the shuttle repository.

If you later want history or analytics, you can mirror RTDB updates into Firestore with a backend job, but that is not required for the current setup.