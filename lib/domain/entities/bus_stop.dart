import 'package:equatable/equatable.dart';

class BusStop extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final String routeId;

  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    required this.routeId,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, order, routeId];
}
