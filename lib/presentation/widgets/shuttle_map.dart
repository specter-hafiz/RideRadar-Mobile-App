import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class ShuttleMap extends StatefulWidget {
  final ShuttleRoute? route;
  final List<Shuttle> shuttles;

  const ShuttleMap({super.key, required this.route, required this.shuttles});

  @override
  State<ShuttleMap> createState() => _ShuttleMapState();
}

class _ShuttleMapState extends State<ShuttleMap> {
  GoogleMapController? _mapController;

  static const _defaultCenter = LatLng(6.6752095, -1.5708816);
  static const _defaultZoom = 16.0;

  @override
  void didUpdateWidget(covariant ShuttleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shuttles.isNotEmpty) {
      _animateCameraToFitShuttles();
    }
  }

  void _animateCameraToFitShuttles() {
    final controller = _mapController;
    if (controller == null || widget.shuttles.isEmpty) return;

    if (widget.shuttles.length == 1) {
      final s = widget.shuttles.first;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(s.latitude, s.longitude), 15),
      );
      return;
    }

    final bounds = _boundsFromShuttles(widget.shuttles);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  LatLngBounds _boundsFromShuttles(List<Shuttle> shuttles) {
    var minLat = shuttles.first.latitude;
    var maxLat = shuttles.first.latitude;
    var minLng = shuttles.first.longitude;
    var maxLng = shuttles.first.longitude;

    for (final s in shuttles) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLng) minLng = s.longitude;
      if (s.longitude > maxLng) maxLng = s.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Set<Polyline> _buildPolylines() {
    final route = widget.route;
    if (route == null || route.polylineCoordinates.isEmpty) return {};

    final color = Color(int.parse(route.colorHex, radix: 16));
    final points = route.polylineCoordinates
        .map((coord) => LatLng(coord[0], coord[1]))
        .toList();

    return {
      Polyline(
        polylineId: PolylineId(route.id),
        points: points,
        color: color,
        width: 4,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final route = widget.route;

    if (route != null) {
      for (final stop in route.stops) {
        markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: stop.name),
          ),
        );
      }
    }

    for (final shuttle in widget.shuttles) {
      markers.add(
        Marker(
          markerId: MarkerId('shuttle_${shuttle.id}'),
          position: LatLng(shuttle.latitude, shuttle.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: shuttle.name,
            snippet: '${shuttle.speed.toStringAsFixed(1)} m/s',
          ),
          rotation: shuttle.heading,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultCenter,
        zoom: _defaultZoom,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (widget.shuttles.isNotEmpty) {
          _animateCameraToFitShuttles();
        }
      },
      polylines: _buildPolylines(),
      markers: _buildMarkers(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
