part of 'exceptions.dart';

/// Thrown when there are issues with voice activity detection.
///
/// This can happen when:
/// - VAD fails to initialize
/// - VAD encounters an error during processing
/// - VAD fails to process audio frames
sealed class VadException extends AgentException {
  const VadException(super.code, super.readableMessage);
}

/// Thrown when VAD encounters an error during processing.
final class VadProcessingError extends VadException {
  const VadProcessingError([String? details])
      : super(
          'vad_processing_error',
          'Error processing audio${details != null ? ': $details' : ''}',
        );
}
