import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_session_manager.dart';

/// Default implementation of [AudioSessionManagerBase] that provides audio session management
/// with configurable audio settings for different use cases.
///
/// This class manages the audio session configuration for both iOS (AVAudioSession) and
/// Android platforms, handling different audio routing scenarios and interruption cases.
final class AudioSessionManager implements AudioSessionManagerBase {
  /// Creates an [AudioSessionManager] with custom audio configuration.
  ///
  /// Use this constructor when you need specific audio session settings different
  /// from the default configurations.
  ///
  /// [configuration] defines the audio session behavior including:
  /// * Audio session category and mode (iOS)
  /// * Bluetooth and speaker options
  /// * Audio attributes (Android)
  /// * Ducking behavior
  AudioSessionManager({required this.configuration});

  /// Creates an [AudioSessionManager] with default configuration optimized for
  /// general media playback and recording.
  ///
  /// This configuration uses the device's main speaker (bottom speaker) when no
  /// headphones are connected. When headphones are connected, audio plays through
  /// the headphones normally.
  ///
  /// Configuration includes:
  /// * Play and record capability
  /// * Bluetooth device support
  /// * Main speaker output (bottom speaker)
  /// * Mixing with other audio
  /// * Speech content type
  /// * Media usage (Android)
  AudioSessionManager.defaultConfig()
      : configuration = AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidWillPauseWhenDucked: false,
        );

  /// Creates an [AudioSessionManager] with configuration optimized for voice calls.
  ///
  /// On iOS, this configuration uses the earpiece speaker (top speaker) when no
  /// headphones are connected, similar to a phone call. When headphones are
  /// connected, audio plays through the headphones normally.
  ///
  /// On Android, the behavior may vary by device manufacturer:
  /// * Some devices will route audio to the earpiece speaker like iOS
  /// * Others may still use the main speaker
  /// * Headphone behavior remains consistent
  ///
  /// Configuration includes:
  /// * Play and record capability
  /// * Bluetooth device support
  /// * Voice chat mode (iOS)
  /// * Voice communication usage (Android)
  /// * Speech content type
  AudioSessionManager.phoneCall()
      : configuration = AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidWillPauseWhenDucked: false,
        );

  /// The audio session configuration that defines the behavior of the audio session.
  final AudioSessionConfiguration configuration;

  /// Internal instance of the audio session.
  AudioSession? _instance;

  @override
  Future<void> initialize() async {
    _instance = await AudioSession.instance;
    await _instance?.configure(configuration);
    await _ensureBluetoothPermissionsOnAndroid();
    return;
  }

  Future<void> _ensureBluetoothPermissionsOnAndroid() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      throw Exception('Bluetooth Permission disabled');
    }
    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      throw Exception('Bluetooth Connect Permission disabled');
    }
  }

  @override
  Stream<AudioDevicesChangedEvent> get devicesChangedStream =>
      _instance?.devicesChangedEventStream ?? const Stream.empty();

  @override
  Stream<Set<AudioDevice>> get devicesStream =>
      _instance?.devicesStream ?? const Stream.empty();

  @override
  Stream<AudioInterruptionEvent> get interruptionStream =>
      _instance?.interruptionEventStream ?? const Stream.empty();

  @override
  Future<bool> startSession() {
    return _instance?.setActive(true) ?? Future.value(false);
  }

  @override
  Future<void> stopSession() {
    return _instance?.setActive(false) ?? Future.value();
  }
}
