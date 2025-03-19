part of 'agent_impl.dart';

base mixin _ClientEvents on _AudioSessionEvents {
  WebSocketChannel? get ws;

  /// Sends {type:'setup'} to the agent.
  void _sendSetupMessage() {
    final setup = <String, dynamic>{
      'type': 'setup',
      'prompt': prompt,
      'inputEncoding': 'mulaw',
      'inputSampleRate': 16000,
      'outputFormat': 'mulaw',
      'outputSampleRate': 44100,
    };
    ws?.sink.add(jsonEncode(setup));
  }

  /// Declares the actions that the agent can perform after the setup message.
  void _sendActionsMessage() {
    if (actions.isEmpty) return;
    final message = <String, dynamic>{
      'type': 'extendConversationSetup',
      'events': actions.map((e) => e.toAgentInstructions()).toList(),
    };
    ws?.sink.add(jsonEncode(message));
  }

  /// Sends {type:'bufferEmpty'} when the player's buffer is empty.
  void _sendBufferEmptyEvent() {
    final msg = <String, dynamic>{'type': 'bufferEmpty'};
    debugPrint('Sending bufferEmpty: ${jsonEncode(msg)}');
    ws?.sink.add(jsonEncode(msg));
  }

  /// Sends a short base64 mu-law silence chunk if the user is muted.
  void _sendAudioInAsSilence(WebSocketChannel ws) {
    final payload = {'type': 'audioIn', 'data': base64MuLawDataForSilence};
    debugPrint('Sending SILENCE: ${payload['data']?.length} bytes');
    ws.sink.add(jsonEncode(payload));
  }

  /// Sends a custom input to the agent.
  void _sendCustomInput(String data) {
    final message = <String, dynamic>{'type': 'customInput', 'data': data};
    ws?.sink.add(jsonEncode(message));
  }

  @override
  Future<void> sendDeveloperMessage(String message) async {
    _log('Sending developer message to agent: $message');
    _sendCustomInput(message);
  }
}
