part of 'exceptions.dart';

/// Thrown when there are issues with audio playback.
///
/// This can happen when:
/// - Failed to initialize audio player
/// - Failed to play audio chunks
/// - Failed to pause/resume playback
sealed class AudioPlayerException extends AgentException {
  const AudioPlayerException(super.code, super.readableMessage);
}

/// Thrown when the audio player fails to initialize or perform operations.
final class AudioPlayerError extends AudioPlayerException {
  const AudioPlayerError([String? details])
      : super(
          'audio_player_error',
          'Audio player error${details != null ? ': $details' : ''}',
        );
}
