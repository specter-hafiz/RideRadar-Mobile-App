part of 'alert_bloc.dart';

final class AlertState extends Equatable {
  final List<ShuttleAlert> alerts;

  const AlertState({this.alerts = const []});

  @override
  List<Object?> get props => [alerts];
}
