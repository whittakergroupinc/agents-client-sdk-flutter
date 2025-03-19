part of 'agent_impl.dart';

base mixin _AudioSessionEvents on _AgentImpl {
  @override
  late final audioSessionManager =
      _audioSessionManager ?? AudioSessionManager.defaultConfig();
  StreamSubscription<AudioInterruptionEvent>? interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? devicesSubscription;

  Future<bool> _createAudioSession() async {
    await audioSessionManager.initialize();
    interruptionSubscription =
        audioSessionManager.interruptionStream.listen((event) {
      callbackConfig.onAudioSessionInterruption?.call(event);
    });
    devicesSubscription =
        audioSessionManager.devicesChangedStream.listen((event) {
      callbackConfig.onAudioDevicesChanged?.call(event);
    });
    return audioSessionManager.startSession();
  }

  @override
  @mustCallSuper
  Future<void> disconnect() async {
    await super.disconnect();
    try {
      await audioSessionManager.stopSession();
      interruptionSubscription?.cancel();
      devicesSubscription?.cancel();
    } catch (e) {
      rethrow;
    } finally {
      interruptionSubscription = null;
      devicesSubscription = null;
    }
  }
}
