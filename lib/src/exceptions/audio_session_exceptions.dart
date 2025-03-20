part of 'exceptions.dart';

/// Thrown when there are issues with the audio session.
///
/// This can happen when:
/// - Failed to create audio session
/// - Failed to configure audio session
/// - Audio session is interrupted
sealed class AudioSessionException extends AgentException {
  const AudioSessionException(super.code, super.readableMessage);
}

/// Thrown when the audio session fails to initialize or start.
final class AudioSessionError extends AudioSessionException {
  const AudioSessionError([String? details])
      : super(
          'audio_session_error',
          'Failed to create audio session${details != null ? ': $details' : ''}',
        );
}
