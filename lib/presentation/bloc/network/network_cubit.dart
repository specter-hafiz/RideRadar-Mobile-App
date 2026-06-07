import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum NetworkStatus { checking, connected, disconnected }

class NetworkState extends Equatable {
  final NetworkStatus status;
  final List<ConnectivityResult> results;

  const NetworkState({required this.status, this.results = const []});

  bool get isConnected => status == NetworkStatus.connected;

  String get summary {
    if (status == NetworkStatus.checking) return 'Checking connection';
    if (status == NetworkStatus.disconnected) return 'No connection';
    if (results.isEmpty) return 'Connected';
    return 'Connected via ${results.map((result) => result.name).join(', ')}';
  }

  @override
  List<Object?> get props => [status, results];
}

class NetworkCubit extends Cubit<NetworkState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(const NetworkState(status: NetworkStatus.checking)) {
    _startMonitoring();
  }

  Future<void> _startMonitoring() async {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _emitFromResults,
      onError: (_) => emit(const NetworkState(status: NetworkStatus.checking)),
    );

    final initialResults = await _connectivity.checkConnectivity();
    _emitFromResults(initialResults);
  }

  void _emitFromResults(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    emit(
      NetworkState(
        status: isConnected
            ? NetworkStatus.connected
            : NetworkStatus.disconnected,
        results: results,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
