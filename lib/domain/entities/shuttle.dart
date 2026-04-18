import 'package:equatable/equatable.dart';

class Shuttle extends Equatable {
  final String id;
  final String name;
  final String routeId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final bool isActive;
  final DateTime lastUpdated;

  const Shuttle({
    required this.id,
    required this.name,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.speed = 0,
    this.isActive = true,
    required this.lastUpdated,
  });

  Shuttle copyWith({
    String? id,
    String? name,
    String? routeId,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return Shuttle(
      id: id ?? this.id,
      name: name ?? this.name,
      routeId: routeId ?? this.routeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        id, name, routeId, latitude, longitude,
        heading, speed, isActive, lastUpdated,
      ];
}
