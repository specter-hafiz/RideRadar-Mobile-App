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

  ShuttleRoute copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    List<BusStop>? stops,
    List<List<double>>? polylineCoordinates,
    bool? isActive,
  }) {
    return ShuttleRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      stops: stops ?? this.stops,
      polylineCoordinates: polylineCoordinates ?? this.polylineCoordinates,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, colorHex, stops,
        polylineCoordinates, isActive,
      ];
}
