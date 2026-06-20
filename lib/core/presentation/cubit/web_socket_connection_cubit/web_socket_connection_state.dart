import 'package:equatable/equatable.dart';

/// UI-facing connection state for the ride socket.
enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

final class WebSocketConnectionState extends Equatable {
  const WebSocketConnectionState({
    this.status = WebSocketConnectionStatus.disconnected,
  });

  final WebSocketConnectionStatus status;

  WebSocketConnectionState copyWith({WebSocketConnectionStatus? status}) {
    return WebSocketConnectionState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
