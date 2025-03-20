part of 'exceptions.dart';

/// Thrown when there are issues with the WebSocket connection.
///
/// This can happen when:
/// - Failed to establish initial connection
/// - Connection is lost during conversation
/// - Server returns an error
sealed class ConnectionException extends AgentException {
  const ConnectionException(super.code, super.readableMessage);
}

/// Thrown when the initial WebSocket connection fails.
final class WebSocketConnectionError extends ConnectionException {
  const WebSocketConnectionError([String? details])
      : super(
          'websocket_connection_error',
          'Failed to connect to the agent${details != null ? ': $details' : ''}',
        );
}
