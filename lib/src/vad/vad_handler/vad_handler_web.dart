// Web implementation of VAD handler
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_handler_web.dart

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import '../../recorder/recorder_base.dart';
import 'vad_handler_base.dart';

/// Start listening for voice activity detection (JS-binding)
@JS('startListeningImpl')
external void startListeningImpl(
  double positiveSpeechThreshold,
  double negativeSpeechThreshold,
  int preSpeechPadFrames,
  int redemptionFrames,
  int frameSamples,
  int minSpeechFrames,
  bool submitUserSpeechOnPause,
  String model,
  String baseAssetPath,
  String onnxWASMBasePath,
);

/// Stop listening for voice activity detection (JS-binding)
@JS('stopListeningImpl')
external void stopListeningImpl();

/// Pause listening for voice activity detection (JS-binding)
@JS('pauseListeningImpl')
external void pauseListeningImpl();

/// Resume listening for voice activity detection (JS-binding)
@JS('resumeListeningImpl')
external void resumeListeningImpl();

/// Check if the VAD is currently listening (JS-binding)
@JS('isListeningNow')
external bool isListeningNow();

/// Log a message to the console (JS-binding)
@JS('logMessage')
external void logMessage(String message);

/// Execute a Dart handler (JS-binding)
@JS('callDartFunction')
external void executeDartHandler();

/// VadHandlerWeb class
class VadHandlerWeb implements VadHandlerBase {
  /// Constructor
  VadHandlerWeb({required bool isDebug}) {
    globalContext['executeDartHandler'] = handleEvent.toJS;
    isDebug = isDebug;
  }
  final StreamController<List<double>> _onSpeechEndController =
      StreamController<List<double>>.broadcast();
  final StreamController<
          ({double isSpeech, double notSpeech, List<double> frame})>
      _onFrameProcessedController = StreamController<
          ({
            double isSpeech,
            double notSpeech,
            List<double> frame
          })>.broadcast();
  final StreamController<void> _onSpeechStartController =
      StreamController<void>.broadcast();
  final StreamController<void> _onRealSpeechStartController =
      StreamController<void>.broadcast();
  final StreamController<void> _onVADMisfireController =
      StreamController<void>.broadcast();
  final StreamController<String> _onErrorController =
      StreamController<String>.broadcast();

  /// Whether to print debug messages
  bool isDebug = false;

  @override
  Stream<List<double>> get onSpeechEnd => _onSpeechEndController.stream;

  @override
  Stream<({double isSpeech, double notSpeech, List<double> frame})>
      get onFrameProcessed => _onFrameProcessedController.stream;

  @override
  Stream<void> get onSpeechStart => _onSpeechStartController.stream;

  @override
  Stream<void> get onRealSpeechStart => _onRealSpeechStartController.stream;

  @override
  Stream<void> get onVADMisfire => _onVADMisfireController.stream;

  @override
  Stream<String> get onError => _onErrorController.stream;

  @override
  void startListening({
    double positiveSpeechThreshold = 0.5,
    double negativeSpeechThreshold = 0.35,
    int preSpeechPadFrames = 1,
    int redemptionFrames = 8,
    int frameSamples = 1536,
    int minSpeechFrames = 3,
    bool submitUserSpeechOnPause = false,
    SileroVADModel model = SileroVADModel.v4,
  }) {
    if (isDebug) {
      debugPrint(
        'VadHandlerWeb: startListening: Calling startListeningImpl with parameters: '
        'positiveSpeechThreshold: $positiveSpeechThreshold, '
        'negativeSpeechThreshold: $negativeSpeechThreshold, '
        'preSpeechPadFrames: $preSpeechPadFrames, '
        'redemptionFrames: $redemptionFrames, '
        'frameSamples: $frameSamples, '
        'minSpeechFrames: $minSpeechFrames, '
        'submitUserSpeechOnPause: $submitUserSpeechOnPause'
        'model: $model',
      );
    }
    startListeningImpl(
      positiveSpeechThreshold,
      negativeSpeechThreshold,
      preSpeechPadFrames,
      redemptionFrames,
      frameSamples,
      minSpeechFrames,
      submitUserSpeechOnPause,
      switch (model) {
        SileroVADModel.v4 => 'legacy',
        SileroVADModel.v5 => 'v5',
      },
      VadHandlerBase.defaultBaseAssetPath,
      VadHandlerBase.defaultOnnxWASMBasePath,
    );
  }

  /// Handle an event from the JS side
  void handleEvent(String eventType, String payload) {
    try {
      final eventData = payload.isNotEmpty
          ? json.decode(payload) as Map<String, dynamic>
          : <String, dynamic>{};

      switch (eventType) {
        case 'onError':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onError: ${eventData['error']}');
          }
          _onErrorController.add(payload);
        case 'onSpeechEnd':
          if (eventData.containsKey('audioData')) {
            final List<double> audioData = (eventData['audioData'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
            if (isDebug) {
              debugPrint(
                'VadHandlerWeb: onSpeechEnd: first 5 samples: ${audioData.sublist(0, 5)}',
              );
            }
            _onSpeechEndController.add(audioData);
          } else {
            if (isDebug) {
              debugPrint('Invalid VAD Data received: $eventData');
            }
          }
        case 'onFrameProcessed':
          if (eventData.containsKey('probabilities') &&
              eventData.containsKey('frame')) {
            final double isSpeech =
                ((eventData['probabilities'] as Map)['isSpeech'] as num)
                    .toDouble();
            final double notSpeech =
                ((eventData['probabilities'] as Map)['notSpeech'] as num)
                    .toDouble();
            final List<double> frame = (eventData['frame'] as List)
                .map((e) => (e as num).toDouble())
                .toList();

            if (isDebug) {
              debugPrint(
                'VadHandlerWeb: onFrameProcessed: isSpeech: $isSpeech, notSpeech: $notSpeech',
              );
            }

            _onFrameProcessedController
                .add((isSpeech: isSpeech, notSpeech: notSpeech, frame: frame));
          } else {
            if (isDebug) {
              debugPrint('Invalid frame data received: $eventData');
            }
          }
        case 'onSpeechStart':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onSpeechStart');
          }
          _onSpeechStartController.add(null);
        case 'onRealSpeechStart':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onRealSpeechStart');
          }
          _onRealSpeechStartController.add(null);
        case 'onVADMisfire':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onVADMisfire');
          }
          _onVADMisfireController.add(null);
        default:
          debugPrint('Unknown event: $eventType');
      }
    } catch (e, st) {
      debugPrint('Error handling event: $e');
      debugPrint('Stack Trace: $st');
    }
  }

  @override
  void dispose() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: dispose');
    }
    _onSpeechEndController.close();
    _onFrameProcessedController.close();
    _onSpeechStartController.close();
    _onRealSpeechStartController.close();
    _onVADMisfireController.close();
    _onErrorController.close();
  }

  @override
  void stopListening() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: stopListening');
    }
    stopListeningImpl();
  }

  @override
  void pauseListening() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: pauseListening');
    }
    pauseListeningImpl();
  }

  @override
  void resumeListening() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: resumeListening');
    }
    resumeListeningImpl();
  }
}

/// Create a VAD handler for the web.
///
/// Parameters:
/// - isDebug: Whether to print debug messages.
/// - recorder: Not used in the web implementation.
VadHandlerBase createVadHandler({
  required bool isDebug,
  RecorderBase? recorder,
}) =>
    VadHandlerWeb(isDebug: isDebug);
