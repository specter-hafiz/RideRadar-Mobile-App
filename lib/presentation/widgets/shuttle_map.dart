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

class _ShuttleMapState extends State<ShuttleMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  BitmapDescriptor? _busStopIcon;
  BitmapDescriptor? _shuttleIcon;
  bool _hasFittedInitialViewport = false;
  bool _isFollowingShuttle = false;

  // For shuttle marker smooth animation
  late final AnimationController _markerPulse;

  static const _defaultCenter = LatLng(6.6752095, -1.5708816);
  static const _defaultZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _markerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    final stopIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(38, 38)),
      'assets/icons/shuttle-stop.png',
    );
    final shuttleIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(52, 52)),
      'assets/icons/shuttle_3d.png',
    );

    if (!mounted) return;
    setState(() {
      _busStopIcon = stopIcon;
      _shuttleIcon = shuttleIcon;
    });
  }

  @override
  void didUpdateWidget(covariant ShuttleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final routeChanged = oldWidget.route?.id != widget.route?.id;
    if (routeChanged) {
      _hasFittedInitialViewport = false;
      _isFollowingShuttle = false;
      _fitViewportIfNeeded();
      return;
    }

    // If following a shuttle, track it as it moves
    if (_isFollowingShuttle && widget.shuttles.isNotEmpty && !routeChanged) {
      final first = widget.shuttles.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(first.latitude, first.longitude)),
      );
    }

    // Auto-fit once when shuttles first appear
    if (!_hasFittedInitialViewport &&
        oldWidget.shuttles.isEmpty &&
        widget.shuttles.isNotEmpty) {
      _fitViewportIfNeeded();
    }
  }

  void _fitViewportIfNeeded() {
    final controller = _mapController;
    if (controller == null) return;

    if (widget.shuttles.isNotEmpty) {
      if (widget.shuttles.length == 1) {
        final s = widget.shuttles.first;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(s.latitude, s.longitude), 15),
        );
      } else {
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromShuttles(widget.shuttles),
            80,
          ),
        );
      }
      _hasFittedInitialViewport = true;
      return;
    }

    final route = widget.route;
    if (route == null) return;

    final routePoints = route.polylineCoordinates
        .map((p) => LatLng(p[0], p[1]))
        .toList();

    if (routePoints.length >= 2) {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromPoints(routePoints), 72),
      );
      _hasFittedInitialViewport = true;
      return;
    }

    if (route.stops.isNotEmpty) {
      final stopPoints = route.stops
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList();
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromPoints(stopPoints), 72),
      );
      _hasFittedInitialViewport = true;
      return;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultCenter, _defaultZoom),
    );
    _hasFittedInitialViewport = true;
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

    // Add a small padding so single-shuttle bounds don't collapse
    const epsilon = 0.001;
    return LatLngBounds(
      southwest: LatLng(minLat - epsilon, minLng - epsilon),
      northeast: LatLng(maxLat + epsilon, maxLng + epsilon),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _recenter() {
    _hasFittedInitialViewport = false;
    _isFollowingShuttle = false;
    _fitViewportIfNeeded();
  }

  void _toggleFollow() {
    setState(() => _isFollowingShuttle = !_isFollowingShuttle);
    if (_isFollowingShuttle && widget.shuttles.isNotEmpty) {
      final first = widget.shuttles.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(first.latitude, first.longitude), 16),
      );
    }
  }

  Set<Polyline> _buildPolylines() {
    final route = widget.route;
    if (route == null || route.polylineCoordinates.isEmpty) return {};

    final color = Color(int.parse(route.colorHex, radix: 16));
    final points = route.polylineCoordinates
        .map((c) => LatLng(c[0], c[1]))
        .toList();

    return {
      // Shadow polyline for depth
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: points,
        color: Colors.black.withValues(alpha: 0.15),
        width: 8,
      ),
      // Main route polyline
      Polyline(
        polylineId: PolylineId(route.id),
        points: points,
        color: color,
        width: 5,
        patterns: [],
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final route = widget.route;

    if (route != null) {
      for (int i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        final isTerminal = i == 0 || i == route.stops.length - 1;

        markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon:
                _busStopIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  isTerminal
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: 'Stop ${stop.order} of ${route.stops.length}',
            ),
            zIndex: isTerminal ? 2.0 : 1.0,
          ),
        );
      }
    }

    for (final shuttle in widget.shuttles) {
      markers.add(
        Marker(
          markerId: MarkerId('shuttle_${shuttle.id}'),
          position: LatLng(shuttle.latitude, shuttle.longitude),
          icon:
              _shuttleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: shuttle.name,
            snippet:
                '${shuttle.speed.toStringAsFixed(1)} m/s · '
                'heading ${shuttle.heading.toStringAsFixed(0)}°',
          ),
          rotation: shuttle.heading,
          anchor: const Offset(0.5, 0.5),
          zIndex: 3.0,
          onTap: () {
            setState(() => _isFollowingShuttle = false);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(shuttle.latitude, shuttle.longitude),
                16,
              ),
            );
          },
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasShuttles = widget.shuttles.isNotEmpty;

    return Stack(
      children: [
        // ── Google Map ────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _defaultCenter,
            zoom: _defaultZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _fitViewportIfNeeded();
          },
          onCameraMoveStarted: () {
            // User started dragging — stop following
            if (_isFollowingShuttle) {
              setState(() => _isFollowingShuttle = false);
            }
          },
          polylines: _buildPolylines(),
          markers: _buildMarkers(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false, // We provide our own controls
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
        ),

        // ── Map control pill (right side) ─────────────────────────────────
        Positioned(
          right: 14,
          bottom: 120,
          child: _MapControlPill(
            onRecenter: _recenter,
            onFollowToggle: hasShuttles ? _toggleFollow : null,
            isFollowing: _isFollowingShuttle,
          ),
        ),

        // ── "Following shuttle" chip ─────────────────────────────────────
        if (_isFollowingShuttle)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Following shuttle',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _markerPulse.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Control Pill
// ─────────────────────────────────────────────────────────────────────────────

class _MapControlPill extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback? onFollowToggle;
  final bool isFollowing;

  const _MapControlPill({
    required this.onRecenter,
    required this.onFollowToggle,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillButton(
            icon: Icons.center_focus_strong_rounded,
            onTap: onRecenter,
          ),
          if (onFollowToggle != null) ...[
            _PillDivider(),
            _PillButton(
              icon: isFollowing
                  ? Icons.gps_fixed_rounded
                  : Icons.gps_not_fixed_rounded,
              onTap: onFollowToggle!,
              isActive: isFollowing,
            ),
          ],
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _PillButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _PillDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 10,
      endIndent: 10,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.25),
    );
  }
}
