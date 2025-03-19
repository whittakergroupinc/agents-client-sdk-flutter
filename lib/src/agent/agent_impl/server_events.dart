part of 'agent_impl.dart';

base mixin _ServerEvents on _ClientEvents {
  AudioPlayer? get player;
  StreamSubscription<dynamic>? wsSubscription;

  void _subscribeToServerEvents() {
    final ws = this.ws;
    if (ws == null) {
      _log(
        'Skipping server event subscription: WebSocket or player not initialized',
      );
      return;
    }
    wsSubscription = ws.stream.listen(
      _handleServerEvent,
      onError: (Object? err) {
        _log('WebSocket error: $err');
        callbackConfig.onError?.call('WebSocket error: $err', true);
        disconnect();
      },
      onDone: () {
        _log('WebSocket closed');
        if (isConnected) {
          callbackConfig.onHangup?.call(HangUpReason.agent);
        }
        disconnect();
      },
    );
  }

  Future<void> _handleServerEvent(dynamic rawEvent) async {
    final player = this.player;
    if (player == null) {
      _log('Skipping server event: Player not initialized');
      return;
    }
    try {
      final parsed = jsonDecode(rawEvent as String) as Map<String, dynamic>;
      final msgType = parsed['type'] as String?;
      switch (msgType) {
        case 'init':
          conversationIdNotifier.value =
              (parsed['conversationId'] as String?) ?? 'unknown';
          isConnectedNotifier.value = true;
          _sendActionsMessage();
          _log(
            'Got init => conversationId=${conversationIdNotifier.value}. Declared ${actions.length} actions.',
          );

        case 'onUserTranscript':
          final userText = parsed['message'] as String? ?? '';
          _log('onUserTranscript => $userText');
          callbackConfig.onUserTranscript?.call(userText);

        case 'onAgentTranscript':
          final agentText = parsed['message'] as String? ?? '';
          _log('onAgentTranscript => $agentText');
          callbackConfig.onAgentTranscript?.call(agentText);

        case 'customEvent':
          final name = parsed['name'] as String;
          final data = Map<String, dynamic>.from(parsed['data'] as Map);
          _log('customEvent => $name: $data');
          try {
            _sendCustomInput(
              'Action $name triggered on client side. Please ask user to wait for a moment while you perform the action. You may not trigger another action until the this one is finished.',
            );
            final result =
                await actions.firstWhere((e) => e.name == name).callback(data);
            _log('customEvent $name result => $result');
            if (result != null) {
              _sendCustomInput(
                'Action $name completed successfully. Here is the frontend response:\n\n"""\n$result\n"""\n\nYou may now trigger another action if needed.',
              );
            }
          } catch (error) {
            _log('customEvent $name ERROR => $error');
            _sendCustomInput(
              'Action $name failed to execute. The error is $error. Please ask user to try again later. You may trigger another action if needed.',
            );
          }

        case 'voiceActivityEnd':
          // user is done, agent is generating.
          _log('voiceActivityEnd => agent decided to speak');
          callbackConfig.onAgentDecidedToSpeak?.call();

        case 'newAudioStream':
          // agent is about to start streaming new audio
          debugPrint('newAudioStream => resetting player');
          callbackConfig.onAgentAudioStreamStarted?.call();
          if (player.isPlaying()) {
            try {
              await player.advance();
              _log('Player buffer reset successfully');
            } catch (e) {
              _log('Error resetting player buffer: $e');
            }
          }

        case 'audioStream':
          // _log('audioStream => ${parsed['data'].length} bytes');
          final base64data = parsed['data'] as String? ?? '';
          if (base64data.isEmpty) {
            callbackConfig.onAgentAudioFrameReceived?.call(null);
          } else {
            final muLawBytes = base64.decode(base64data);
            final pcm16Bytes = decodeMuLawToPCM16(muLawBytes);
            callbackConfig.onAgentAudioFrameReceived?.call(pcm16Bytes);
            await player.feed(pcm16Bytes);
          }

        case 'audioStreamEnd':
          // finished streaming the mp3 for this utterance
          _log('audioStreamEnd => finalizing mp3 and playing...');
          callbackConfig.onAgentAudioStreamEnded?.call();

        case 'error':
          final isFatal = parsed['isFatal'] as bool? ?? false;
          final code = parsed['code'] ?? 'unknown';
          final message = parsed['message'] as String? ?? 'unknown error';
          _log('Got error => $message (code:$code, fatal:$isFatal)');
          callbackConfig.onError?.call('$message (code:$code)', isFatal);
          if (isFatal) {
            _log('Fatal => cleaning up...');
            disconnect();
            callbackConfig.onHangup?.call(HangUpReason.error);
          }

        case 'hangup':
          // agent ended the conversation
          _log('Got hangup => cleaning up...');
          disconnect();
          callbackConfig.onHangup?.call(HangUpReason.agent);

        default:
        // _log('Unhandled message type: $msgType');
      }
    } catch (e, st) {
      _log('Error parsing server event: $e\n$st');
      callbackConfig.onError?.call('Parsing server event: $e', false);
    }
  }

  @override
  @mustCallSuper
  Future<void> disconnect() async {
    await super.disconnect();
    wsSubscription?.cancel();
    wsSubscription = null;
  }
}
