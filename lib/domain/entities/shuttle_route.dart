import 'package:equatable/equatable.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';

class ShuttleRoute extends Equatable {
  final String id;
  final String name;
  final String description;
  final String colorHex;
  final List<BusStop> stops;
  final List<List<double>> polylineCoordinates;
  final bool isActive;

  const ShuttleRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.stops,
    required this.polylineCoordinates,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id, name, description, colorHex, stops,
        polylineCoordinates, isActive,
      ];
}
