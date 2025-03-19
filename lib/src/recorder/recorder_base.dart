/// An interface for streaming audio data.
///
/// This class provides methods to handle audio streaming operations including
/// permission management, starting and stopping the audio stream.
abstract interface class RecorderBase {
  /// Checks if the application has the necessary permissions to access audio.
  ///
  /// Returns a [Future] that completes with:
  /// * `true` if the app has audio permissions
  /// * `false` if the app doesn't have audio permissions
  Future<bool> hasPermission();

  /// Starts streaming audio data.
  ///
  /// Returns a [Stream] of byte arrays representing the audio data.
  /// Each list contains a chunk of audio data as integers.
  Future<Stream<List<int>>> startStream();

  /// Pauses the currently running audio stream.
  Future<void> pauseStream();

  /// Resumes the currently running audio stream.
  Future<void> resumeStream();

  /// Stops the currently running audio stream.
  ///
  /// Returns a [Future] that completes when the stream has been stopped.
  Future<void> stopStream();

  /// Disposes the audio streamer if it is not needed anymore.
  Future<void> dispose();
}
