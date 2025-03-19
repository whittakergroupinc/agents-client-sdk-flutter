// VAD handler interface
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_handler_base.dart

import 'dart:async';

/// Abstract class for VAD handler
abstract class VadHandlerBase {
  static const defaultBaseAssetPath = 'assets/packages/vad/assets/';
  static const defaultOnnxWASMBasePath = 'assets/packages/vad/assets/';

  /// Stream of speech end events
  Stream<List<double>> get onSpeechEnd;

  /// Stream of frame processed events
  Stream<({double isSpeech, double notSpeech, List<double> frame})>
      get onFrameProcessed;

  /// Stream of speech start events
  Stream<void> get onSpeechStart;

  /// Stream of real speech start events
  Stream<void> get onRealSpeechStart;

  /// Stream of VAD misfire events
  Stream<void> get onVADMisfire;

  /// Stream of error events
  Stream<String> get onError;

  /// Start listening for speech events
  void startListening({
    double positiveSpeechThreshold = 0.5,
    double negativeSpeechThreshold = 0.35,
    int preSpeechPadFrames = 1,
    int redemptionFrames = 8,
    int frameSamples = 512,
    int minSpeechFrames = 3,
    bool submitUserSpeechOnPause = false,
    SileroVADModel model = SileroVADModel.v5,
  });

  /// Stop listening for speech events
  void stopListening();

  /// Pause listening for speech events
  void pauseListening();

  /// Resume listening for speech events
  void resumeListening();

  /// Dispose the VAD handler
  void dispose();
}

enum SileroVADModel {
  v4,
  v5,
}
