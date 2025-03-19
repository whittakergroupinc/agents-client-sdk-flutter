part of 'interfaces.dart';

class AgentCallbackConfig {
  const AgentCallbackConfig({
    this.debug = kDebugMode,
    this.onUserTranscript,
    this.onAgentTranscript,
    this.onUserStartedSpeaking,
    this.onUserStoppedSpeaking,
    this.onAgentStartedSpeaking,
    this.onAgentStoppedSpeaking,
    this.onAgentDecidedToSpeak,
    this.onAgentAudioStreamStarted,
    this.onAgentAudioFrameReceived,
    this.onAgentAudioStreamEnded,
    this.onError,
    this.onAudioSessionInterruption,
    this.onAudioDevicesChanged,
    this.onHangup,
    this.onVADStartedListening,
    this.onVADSpeechStart,
    this.onVADSpeechEnd,
    this.onVADFrameProcessed,
    this.onAudioStreamerFrameRecorded,
  });

  final bool debug;

  /// Fired each time user’s transcript is recognized
  final void Function(String transcript)? onUserTranscript;

  /// Fired when agent’s transcript is generated
  final void Function(String transcript)? onAgentTranscript;

  /// Fired when user speech is detected
  final VoidCallback? onUserStartedSpeaking;

  /// Fired when user speech ends
  final VoidCallback? onUserStoppedSpeaking;

  /// Fired when agent actually starts playing audio
  final VoidCallback? onAgentStartedSpeaking;

  /// Fired when agent stops playing audio
  final VoidCallback? onAgentStoppedSpeaking;

  /// Fired when agent decides to speak (i.e. user is done, agent is generating)
  final VoidCallback? onAgentDecidedToSpeak;

  /// Fired when agent audio stream starts
  final VoidCallback? onAgentAudioStreamStarted;

  /// Fired when agent audio frame is received
  final void Function(Uint8List? frame)? onAgentAudioFrameReceived;

  /// Fired when agent audio stream ends
  final VoidCallback? onAgentAudioStreamEnded;

  /// Fired on recoverable or fatal error
  /// (errorMessage, isFatal)
  final void Function(String error, bool isFatal)? onError;

  // Fired when the audio session emits interruption events
  final void Function(AudioInterruptionEvent event)? onAudioSessionInterruption;

  /// Fired when the audio devices change
  final void Function(AudioDevicesChangedEvent event)? onAudioDevicesChanged;

  /// Fired when conversation ends or the connection is closed
  final ValueChanged<HangUpReason>? onHangup;

  /// Fired when VAD starts listening
  final VoidCallback? onVADStartedListening;

  /// Fired when VAD detects speech start
  final VoidCallback? onVADSpeechStart;

  /// Fired when VAD detects speech end
  final VoidCallback? onVADSpeechEnd;

  /// Fired when VAD detects a frame
  final void Function(
    ({double isSpeech, double notSpeech, List<double> frame}) frame,
  )? onVADFrameProcessed;

  /// Fired when AudioStreamer records a frame
  final void Function(List<int> frame)? onAudioStreamerFrameRecorded;
}
