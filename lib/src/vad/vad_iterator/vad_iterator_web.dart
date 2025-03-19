// VAD iterator for web
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_iterator_web.dart

import '../vad.dart';
import 'vad_iterator_base.dart';

/// VadIteratorWeb class.
///
/// Do not use this class directly.
/// Use [VadIterator.create] instead.
class VadIteratorWeb implements VadIteratorBase {
  @override
  void forceEndSpeech() {
    throw UnimplementedError();
  }

  @override
  Future<void> initModel(String modelPath) {
    throw UnimplementedError();
  }

  @override
  Future<void> processAudioData(List<int> data) {
    throw UnimplementedError();
  }

  @override
  void release() {
    throw UnimplementedError();
  }

  @override
  void reset() {
    throw UnimplementedError();
  }

  @override
  void setVadEventCallback(VadEventCallback callback) {
    throw UnimplementedError();
  }
}

/// Create VadHandlerNonWeb instance.
///
/// None of the parameters are used in the web implementation.
VadIteratorBase createVadIterator({
  required bool isDebug,
  required int sampleRate,
  required int frameSamples,
  required double positiveSpeechThreshold,
  required double negativeSpeechThreshold,
  required int redemptionFrames,
  required int preSpeechPadFrames,
  required int minSpeechFrames,
  required bool submitUserSpeechOnPause,
  required SileroVADModel model,
}) {
  return VadIteratorWeb();
}
