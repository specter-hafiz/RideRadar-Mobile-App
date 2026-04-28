import 'package:shuttletrack/domain/entities/bus_stop.dart';

/// All physical bus stops on the KNUST campus network.
///
/// Coordinates are (latitude, longitude) in WGS-84.
/// Stops shared between routes use the same [id] so the UI can
/// highlight "this stop appears on N routes".
abstract final class KnustStops {
  // ── Route 1 & 2 ────────────────────────────────────────────────────────────

  static const commercialArea = (
    id: 'commercial_area',
    name: 'Commercial Area Bus Stop',
    lat: 6.682740,
    lng: -1.576994,
  );

  static const peaceBusStop = (
    id: 'peace_hall7_a',
    name: 'Peace Bus Stop (Hall 7 – Stop A)',
    lat: 6.679293,
    lng: -1.572800,
  );

  static const hall7BusStop = (
    id: 'hall7_b',
    name: 'Hall 7 Bus Stop (Stop B)',
    lat: 6.679641,
    lng: -1.572970,
  );

  static const pharmacyBusStop = (
    id: 'pharmacy',
    name: 'Pharmacy Bus Stop',
    lat: 6.674538,
    lng: -1.567575,
  );

  static const ksbBusStop = (
    id: 'ksb_trinity',
    name: 'KSB Bus Stop (Trinity)',
    lat: 6.669322,
    lng: -1.567175,
  );

  static const casleyHayford = (
    id: 'casley_hayford',
    name: 'Casley Hayford Bus Stop (SRC)',
    lat: 6.675213,
    lng: -1.567860,
  );

  // ── Route 2 ────────────────────────────────────────────────────────────────

  static const brunei = (
    id: 'brunei',
    name: 'Brunei Bus Stop',
    lat: 6.670441,
    lng: -1.574152,
  );

  static const prempehLibrary = (
    id: 'prempeh_library',
    name: 'Prempeh Library',
    lat: 6.675086,
    lng: -1.572899,
  );

  // ── Routes 3, 4, 5 ────────────────────────────────────────────────────────

  static const gazaBusStop = (
    id: 'gaza',
    name: 'Gaza Bus Stop',
    lat: 6.687602,
    lng: -1.557034,
  );

  static const medicalVillage = (
    id: 'medical_village',
    name: 'Medical Village',
    lat: 6.681121,
    lng: -1.549854,
  );

  /// "Bus stop opposite Agric" and "Agric bus stop" share the same location.
  static const agric = (
    id: 'agric',
    name: 'Agric Bus Stop',
    lat: 6.674820,
    lng: -1.566526,
  );
}

// ─── Helper extension ─────────────────────────────────────────────────────────

extension StopRecordToBusStop
    on ({String id, String name, double lat, double lng}) {
  /// Converts the lightweight record into a domain [BusStop] entity.
  BusStop toBusStop({required int order, required String routeId}) => BusStop(
    id: '${routeId}_$id',
    name: name,
    latitude: lat,
    longitude: lng,
    order: order,
    routeId: routeId,
  );
}
