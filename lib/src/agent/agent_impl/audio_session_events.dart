part of 'agent_impl.dart';

base mixin _AudioSessionEvents on _AgentImpl {
  AudioSessionManagerBase get _session => audioSessionManager;
  StreamSubscription<AudioInterruptionEvent>? interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? devicesSubscription;

  Future<bool> _createAudioSession() async {
    await _session.initialize();
    interruptionSubscription = _session.interruptionStream.listen((event) {
      callbackConfig.onAudioSessionInterruption?.call(event);
    });
    devicesSubscription = _session.devicesChangedStream.listen((event) {
      callbackConfig.onAudioDevicesChanged?.call(event);
    });
    return _session.startSession();
  }

  @override
  @mustCallSuper
  Future<void> disconnect() async {
    await super.disconnect();
    try {
      await _session.stopSession();
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
