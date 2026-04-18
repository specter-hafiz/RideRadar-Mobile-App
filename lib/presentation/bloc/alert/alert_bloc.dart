import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/domain/entities/shuttle_alert.dart';

part 'alert_event.dart';
part 'alert_state.dart';

class AlertBloc extends Bloc<AlertEvent, AlertState> {
  AlertBloc() : super(const AlertState()) {
    on<AddAlert>(_onAddAlert);
    on<ClearAlerts>(_onClearAlerts);
  }

  void _onAddAlert(AddAlert event, Emitter<AlertState> emit) {
    emit(AlertState(alerts: [event.alert, ...state.alerts]));
  }

  void _onClearAlerts(ClearAlerts event, Emitter<AlertState> emit) {
    emit(const AlertState());
  }
}
