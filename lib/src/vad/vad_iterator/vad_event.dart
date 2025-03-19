// ignore_for_file: public_member_api_docs, sort_constructors_first
// VAD event class
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_event.dart

import 'package:flutter/foundation.dart';

/// Types of VAD events
enum VadEventType {
  /// Speech start event
  start,

  /// Real speech start event
  realStart,

  /// Speech end event
  end,

  /// Frame processed event
  frameProcessed,

  /// VAD misfire event
  misfire,

  /// Error event
  error,
}

/// Type signature for VAD event callback.
typedef VadEventCallback = void Function(VadEvent event);

/// Speech probability of a frame
@immutable
class SpeechProbabilities {
  const SpeechProbabilities({
    required this.isSpeech,
    required this.notSpeech,
  });

  /// Probability of speech
  final double isSpeech;

  /// Probability of not speech
  final double notSpeech;

  SpeechProbabilities copyWith({
    double? isSpeech,
    double? notSpeech,
  }) {
    return SpeechProbabilities(
      isSpeech: isSpeech ?? this.isSpeech,
      notSpeech: notSpeech ?? this.notSpeech,
    );
  }

  @override
  String toString() =>
      'SpeechProbabilities(isSpeech: $isSpeech, notSpeech: $notSpeech)';

  @override
  bool operator ==(covariant SpeechProbabilities other) {
    if (identical(this, other)) return true;

    return other.isSpeech == isSpeech && other.notSpeech == notSpeech;
  }

  @override
  int get hashCode => isSpeech.hashCode ^ notSpeech.hashCode;
}

/// VadEvent class
@immutable
class VadEvent {
  const VadEvent({
    required this.type,
    required this.timestamp,
    required this.message,
    this.audioData,
    this.probabilities,
    this.frameData,
  });

  /// VadEventType
  final VadEventType type;

  /// Timestamp
  final double timestamp;

  /// Message
  final String message;

  /// Audio data
  final Uint8List? audioData;

  /// Speech probabilities
  final SpeechProbabilities? probabilities;

  /// Frame data
  final List<double>? frameData;

  VadEvent copyWith({
    VadEventType? type,
    double? timestamp,
    String? message,
    Uint8List? audioData,
    SpeechProbabilities? probabilities,
    List<double>? frameData,
  }) {
    return VadEvent(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      audioData: audioData ?? this.audioData,
      probabilities: probabilities ?? this.probabilities,
      frameData: frameData ?? this.frameData,
    );
  }

  @override
  String toString() {
    return 'VadEvent(type: $type, timestamp: $timestamp, message: $message, audioData: ${audioData?.length}, probabilities: $probabilities, frameData: $frameData)';
  }

  @override
  bool operator ==(covariant VadEvent other) {
    if (identical(this, other)) return true;

    return other.type == type &&
        other.timestamp == timestamp &&
        other.message == message &&
        other.audioData == audioData &&
        other.probabilities == probabilities &&
        listEquals(other.frameData, frameData);
  }

  @override
  int get hashCode {
    return type.hashCode ^
        timestamp.hashCode ^
        message.hashCode ^
        audioData.hashCode ^
        probabilities.hashCode ^
        frameData.hashCode;
  }
}
