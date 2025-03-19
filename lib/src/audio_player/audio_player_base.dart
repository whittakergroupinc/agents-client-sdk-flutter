import 'dart:async';

import 'package:flutter/foundation.dart';

/// An abstract interface that defines the base functionality for raw audio playback
/// (PCM16 encoded audio data).
///
/// Implement this interface to pass to [Agent] if custom playback is required.
///
/// See also:
/// * [AudioPlayer] - The default implementation of this interface.
abstract interface class AudioPlayerBase {
  /// Callback that is triggered when the audio queue becomes empty.
  ///
  /// This can be used to handle scenarios where all audio chunks have been played.
  VoidCallback? get onEmptyQueue;

  /// A stream that emits the current playing state of the audio player.
  ///
  /// Emits `true` when audio is playing, `false` when paused or stopped.
  Stream<bool> get playingStream;

  /// Checks if audio is currently playing.
  ///
  /// Returns `true` if audio is playing, `false` otherwise.
  FutureOr<bool> isPlaying();

  /// Initializes the audio player.
  ///
  /// This method should be called before any other operations to set up
  /// necessary resources and configurations.
  Future<void> initialize();

  /// Feeds a PCM16 encoded audio chunk to the player's queue.
  ///
  /// [pcm16Chunk] is a Uint8List containing the PCM16 encoded audio data
  /// to be queued for playback.
  Future<void> feed(Uint8List pcm16Chunk);

  /// Clears the current audio queue and restarts the player.
  Future<void> advance();

  /// Pauses the current audio playback.
  ///
  /// The playback can be resumed from the paused position using [resume].
  Future<void> pause();

  /// Resumes audio playback from the paused position.
  ///
  /// This method should only be called after [pause] has been called.
  Future<void> resume();

  /// Stops the current audio playback and clears the queue.
  Future<void> stop();

  /// Releases resources used by the audio player.
  ///
  /// Should be called when the audio player is no longer needed to clean up resources.
  Future<void> dispose();
}
