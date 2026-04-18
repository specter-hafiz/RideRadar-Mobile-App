part of 'alert_bloc.dart';

sealed class AlertEvent extends Equatable {
  const AlertEvent();
  @override
  List<Object?> get props => [];
}

final class AddAlert extends AlertEvent {
  final ShuttleAlert alert;
  const AddAlert(this.alert);
  @override
  List<Object?> get props => [alert];
}

final class ClearAlerts extends AlertEvent {
  const ClearAlerts();
}
