part of 'exceptions.dart';

/// Thrown when the server returns an error response.
///
/// This can happen when:
/// - Server returns an error message
/// - Server encounters an internal error
/// - Server rejects the request
sealed class ServerException extends AgentException {
  const ServerException(
    super.code,
    super.readableMessage, {
    this.isFatal = false,
  });

  /// Whether this error is fatal and requires disconnecting
  final bool isFatal;
}

/// Thrown when the server returns a specific error message.
final class ServerError extends ServerException {
  const ServerError({
    required String code,
    required String message,
    required bool isFatal,
  }) : super(code, message, isFatal: isFatal);
}
