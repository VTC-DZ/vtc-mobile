import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../network/ride_socket_service.dart';
import 'web_socket_connection_state.dart';

/// Reactive view over [RideSocketService.statusStream].
///
/// Pure observer: connection/disconnection is driven by feature code (e.g. the
/// driver availability toggle) through [RideSocketService] directly; this cubit
/// only mirrors the resulting status so widgets can `BlocBuilder` on it.
class WebSocketConnectionCubit extends Cubit<WebSocketConnectionState> {
  WebSocketConnectionCubit() : super(const WebSocketConnectionState()) {
    _subscription = RideSocketService.statusStream.listen(_onStatus);
  }

  late final StreamSubscription<RideSocketStatus> _subscription;

  void _onStatus(RideSocketStatus status) {
    emit(state.copyWith(status: _mapStatus(status)));
  }

  static WebSocketConnectionStatus _mapStatus(RideSocketStatus status) {
    return switch (status) {
      RideSocketStatus.disconnected => WebSocketConnectionStatus.disconnected,
      RideSocketStatus.connecting => WebSocketConnectionStatus.connecting,
      RideSocketStatus.connected => WebSocketConnectionStatus.connected,
      RideSocketStatus.reconnecting => WebSocketConnectionStatus.reconnecting,
      RideSocketStatus.failed => WebSocketConnectionStatus.failed,
    };
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
