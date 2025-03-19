import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_session_manager.dart';

final class AudioSessionManager implements AudioSessionManagerBase {
  AudioSessionManager({this.configuration});

  static final defaultAudioConfiguration = AudioSessionConfiguration(
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

  final AudioSessionConfiguration? configuration;

  AudioSession? _instance;

  @override
  Future<void> initialize() async {
    _instance = await AudioSession.instance;
    await _instance?.configure(configuration ?? defaultAudioConfiguration);
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
