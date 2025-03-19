// VAD iterator base class
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_iterator_base.dart

import 'vad_event.dart';

abstract class VadIteratorBase {
  /// Initialize the VAD model from the given [modelPath].
  Future<void> initModel(String modelPath);

  /// Reset the VAD iterator.
  void reset();

  /// Release the VAD iterator resources.
  void release();

  /// Set the VAD event callback.
  void setVadEventCallback(VadEventCallback callback);

  /// Process audio data.
  Future<void> processAudioData(List<int> data);

  /// Forcefully end speech detection on pause/stop event.
  void forceEndSpeech();
}
