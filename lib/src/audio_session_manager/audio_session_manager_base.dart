import 'package:audio_session/audio_session.dart';

/// An abstract interface that defines the base functionality for managing audio sessions.
///
/// This interface provides methods and streams to handle audio session lifecycle,
/// interruptions (like phone calls or other apps playing audio), and audio device changes.
/// It's essential for proper audio handling in mobile applications.
///
/// Implement this interface to pass to [Agent] if custom audio session management is required.
///
/// See also:
/// * [AudioSession] from the audio_session package which this interface wraps.
/// * [AudioSessionManager] - The default implementation of this interface.
abstract interface class AudioSessionManagerBase {
  /// Initializes the audio session manager with default configuration.
  ///
  /// This should be called before starting any audio session to set up the necessary
  /// system audio configurations.
  Future<void> initialize();

  /// Starts an audio session with the configured settings.
  ///
  /// Returns `true` if the session was successfully started, `false` otherwise.
  /// This should be called before beginning audio playback.
  Future<bool> startSession();

  /// Stops the current audio session.
  ///
  /// This should be called when audio playback is complete or the app no longer
  /// needs to maintain an active audio session.
  Future<void> stopSession();

  /// A stream of audio interruption events.
  ///
  /// Emits events when audio is interrupted by other apps, phone calls, or system events.
  /// Apps should respond to these events by pausing/resuming playback appropriately.
  Stream<AudioInterruptionEvent> get interruptionStream;

  /// A stream of audio device change events.
  ///
  /// Emits events when audio devices are connected or disconnected
  /// (e.g., headphones, bluetooth devices).
  Stream<AudioDevicesChangedEvent> get devicesChangedStream;

  /// A stream that emits the current set of available audio devices.
  ///
  /// The set contains all currently available audio devices that can be used
  /// for playback or recording.
  Stream<Set<AudioDevice>> get devicesStream;
}
