import 'package:audio_session/audio_session.dart';

abstract interface class AudioSessionManagerBase {
  Future<void> initialize();
  Future<bool> startSession();
  Future<void> stopSession();
  Stream<AudioInterruptionEvent> get interruptionStream;
  Stream<AudioDevicesChangedEvent> get devicesChangedStream;
  Stream<Set<AudioDevice>> get devicesStream;
}
