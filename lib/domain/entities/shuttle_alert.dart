import 'package:equatable/equatable.dart';

class ShuttleAlert extends Equatable {
  final String id;
  final String shuttleName;
  final String stopName;
  final String routeName;
  final String message;
  final DateTime timestamp;

  const ShuttleAlert({
    required this.id,
    required this.shuttleName,
    required this.stopName,
    required this.routeName,
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, shuttleName, stopName, routeName, message, timestamp];
}
