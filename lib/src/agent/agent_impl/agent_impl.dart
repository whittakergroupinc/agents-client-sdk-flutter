import 'dart:async';
import 'dart:convert' hide Codec;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vad/vad.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../audio_player/audio_player.dart';
import '../../audio_session_manager/audio_session_manager.dart';
import '../../exceptions/exceptions.dart';
import '../agent.dart';

final class AgentBase implements Agent {
  AgentBase({
    required this.baseUrl,
    required this.agentId,
    required this.prompt,
    required this.actions,
    required AudioSessionManagerBase? audioSessionManager,
    required this.callbackConfig,
    required AudioPlayerBase? player,
  }) {
    _audioSessionManager = audioSessionManager;
    _player = player;
    _createVadHandler();
  }

  @override
  final String baseUrl;

  @override
  final String agentId;

  @override
  final String prompt;

  @override
  final List<AgentAction> actions;

  @override
  final AgentCallbackConfig callbackConfig;

  // ------------------------------------------------------------
  // Start of Controllers: Audio Session, Recorder, VAD, Player, WebSocket
  // ------------------------------------------------------------

  @override
  late final audioSessionManager =
      _audioSessionManager ?? AudioSessionManager.defaultConfig();
  StreamSubscription<AudioInterruptionEvent>? interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? devicesSubscription;
  late final AudioSessionManagerBase? _audioSessionManager;

  @override
  late final vadHandler = VadHandler.create(isDebug: false);
  Timer? _vadPauseTimer;

  @override
  late final AudioPlayerBase player = _player ?? AudioPlayer();
  late final AudioPlayerBase? _player;
  StreamSubscription<bool>? playerSubscription;

  WebSocketChannel? ws;
  StreamSubscription<dynamic>? wsSubscription;

  // ------------------------------------------------------------
  // End of Controllers
  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // Start of State Notifiers
  // ------------------------------------------------------------

  @override
  final ValueNotifier<String?> conversationIdNotifier =
      ValueNotifier<String?>(null);

  @override
  final ValueNotifier<AgentState> stateNotifier =
      ValueNotifier<AgentState>(AgentState.idle);

  @override
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<bool> isAgentSpeakingNotifier =
      ValueNotifier<bool>(false);

  @override
  final ValueNotifier<bool> isUserSpeakingNotifier = ValueNotifier<bool>(false);

  // ------------------------------------------------------------
  // End of State Notifiers
  // ------------------------------------------------------------

  void _log(String message) {
    if (callbackConfig.debug) {
      // ignore: avoid_print
      print('[AGENT] $message');
    }
  }

  @override
  Future<void> connect() async {
    if (state != AgentState.idle) {
      throw InvalidAgentState(state, 'connect');
    }

    stateNotifier.value = AgentState.connecting;

    try {
      await _ensureMicrophonePermission();
      await _initializeAudioPlayer();
      await _connectWebSocket();
      _subscribeToServerEvents();
      _sendSetupMessage();

      _log('Listening to VAD frames...');
      callbackConfig.onVADStartedListening?.call();
      vadHandler.startListening();

      final canStartSession = await Future<bool>.delayed(
        const Duration(milliseconds: 300),
        _createAudioSession,
      );

      if (!canStartSession) {
        throw const AudioSessionError('Failed to start audio session');
      }

      stateNotifier.value = AgentState.connected;

      return;
    } catch (e) {
      _log('Error during connect: $e');
      await disconnect();
      if (e is AgentException) {
        rethrow;
      }
      throw WebSocketConnectionError(e.toString());
    }
  }

  @override
  Future<void> muteUser() async {
    if (isMuted) return;
    isMutedNotifier.value = true;
    _log('User mic muted => sending silence');
  }

  @override
  Future<void> unmuteUser() async {
    if (!isMuted) return;
    isMutedNotifier.value = false;
    _log('User mic unmuted');
  }

  @override
  Future<void> disconnect() async {
    if (state == AgentState.idle) throw const NoConversationInProgress();
    if (state == AgentState.disconnecting) return; // Already disconnecting

    stateNotifier.value = AgentState.disconnecting;

    try {
      _log('resetting agent...');
      await ws?.sink.close();
      await wsSubscription?.cancel();

      await audioSessionManager.stopSession();
      interruptionSubscription?.cancel();
      devicesSubscription?.cancel();

      await player.stop();
      playerSubscription?.cancel();

      _vadPauseTimer?.cancel();
      vadHandler.stopListening();
    } catch (e) {
      _log('Error during reset: $e');
    } finally {
      _log('Agent reset');
      ws = null;
      wsSubscription = null;

      interruptionSubscription = null;
      devicesSubscription = null;

      playerSubscription = null;

      _vadPauseTimer = null;

      callbackConfig.onHangup?.call(HangUpReason.user);
      isConnectedNotifier.value = false;
      isUserSpeakingNotifier.value = false;
      isAgentSpeakingNotifier.value = false;
      isMutedNotifier.value = false;
      stateNotifier.value = AgentState.idle;
    }
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    // Disconnect from the agent
    try {
      await disconnect();
    } catch (_) {
      // ignore
    }

    // Dispose of controllers
    if (_player == null) await player.dispose();
    vadHandler.dispose();

    // Dispose of notifiers
    stateNotifier.dispose();
    isConnectedNotifier.dispose();
    isMutedNotifier.dispose();
    isAgentSpeakingNotifier.dispose();
    isUserSpeakingNotifier.dispose();
  }

  // ------------------------------------------------------------
  // Audio Session, Player, & WebSocket
  // ------------------------------------------------------------

  Future<bool> _createAudioSession() async {
    await audioSessionManager.initialize();
    interruptionSubscription =
        audioSessionManager.interruptionStream.listen((event) {
      callbackConfig.onAudioSessionInterruption?.call(event);
    });
    devicesSubscription =
        audioSessionManager.devicesChangedStream.listen((event) {
      callbackConfig.onAudioDevicesChanged?.call(event);
    });
    return audioSessionManager.startSession();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      player.onEmptyQueue = _sendBufferEmptyEvent;
      await player.initialize();
      // Listen to player states to detect agent's start/stop speaking
      playerSubscription = player.playingStream.listen(
        (isPlaying) {
          if (!isConnected) return;

          // onAgentStartedSpeaking
          if (isPlaying && !isAgentSpeaking) {
            isAgentSpeakingNotifier.value = true;
            _log('Agent started speaking (playing audio)');
            callbackConfig.onAgentStartedSpeaking?.call();
          }

          // onAgentStoppedSpeaking
          if (!isPlaying && isAgentSpeaking) {
            isAgentSpeakingNotifier.value = false;
            _log('Agent stopped speaking');
            callbackConfig.onAgentStoppedSpeaking?.call();
          }
        },
        onError: (Object error) {
          _log('Audio player error: $error');
          throw AudioPlayerError(error.toString());
        },
      );
    } catch (e) {
      _log('Failed to initialize audio player: $e');
      if (e is AgentException) {
        rethrow;
      }
      throw AudioPlayerError(e.toString());
    }
  }

  Future<void> _connectWebSocket() async {
    assert(ws == null, 'WebSocket already connected!');
    _log('Connecting WebSocket to the agent...');
    final wsUrl = Uri.parse('$baseUrl/v1/agents/$agentId/start-conversation');
    try {
      ws = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: const Duration(seconds: 10),
      );
      _log('WebSocket connected');
    } catch (e) {
      _log('Failed to connect WebSocket: $e');
      throw WebSocketConnectionError(e.toString());
    }
  }

  // ------------------------------------------------------------
  // VAD
  // ------------------------------------------------------------

  Future<void> _ensureMicrophonePermission() async {
    final permissionStatus = await Permission.microphone.request();
    _log('Microphone permission: $permissionStatus');
    if (!permissionStatus.isGranted) {
      throw const MicrophonePermissionDenied();
    }
  }

  void _createVadHandler() {
    // 8) Hook up VAD:
    //    - threshold of 0.85
    //    - a 1s pause to confirm user is done speaking
    void resetPauseTimer() {
      _vadPauseTimer?.cancel();
      _vadPauseTimer = Timer(
        const Duration(milliseconds: defaultVadPauseTimeoutMs),
        () {
          // user definitely finished speaking
          if (isUserSpeaking) {
            isUserSpeakingNotifier.value = false;
            _log('User stopped speaking => resume agent audio');
            callbackConfig.onUserStoppedSpeaking?.call();
            player.resume().catchError((Object? err) {
              _log('Error trying to resume audio: $err');
            });
          }
        },
      );
    }

    vadHandler.onFrameProcessed.listen(
      (frame) {
        try {
          callbackConfig.onVADFrameProcessed?.call(frame);
          if (!isConnected) {
            // Skip if agent not ready
            return _log('Skipping VAD frame: agent not connected yet.');
          }
          if (isMuted) {
            // Send keep-alive silence
            _sendAudioInAsSilence();
            return;
          }
          final prob = frame.isSpeech;
          if (prob > defaultVadThreshold) {
            if (!isUserSpeaking) {
              isUserSpeakingNotifier.value = true;
              _log('User started speaking => pause agent audio');
              callbackConfig.onUserStartedSpeaking?.call();
              // Immediately pause agent playback so they don't talk over each other
              player.pause().catchError((Object? err) {
                _log('Error pausing agent audio: $err');
                throw AudioPlayerError(err.toString());
              });
            }
            // Reset the "stop speaking" countdown
            resetPauseTimer();
          }

          // Always send frames, even if prob < threshold,
          // because server wants continuous input.
          final encoded = encodeFloat32FrameToMuLaw(frame.frame);
          final b64 = base64.encode(encoded);
          _sendAudioIn(b64);
        } catch (e) {
          _log('Error processing VAD frame: $e');
          if (e is AgentException) {
            rethrow;
          }
          throw VadProcessingError(e.toString());
        }
      },
      onError: (Object error) {
        _log('VAD error: $error');
        callbackConfig.onError?.call('VAD error: $error', false);
        throw VadProcessingError(error.toString());
      },
    );
    vadHandler.onSpeechStart.listen((_) {
      _log('VAD onSpeechStart');
      callbackConfig.onVADSpeechStart?.call();
    });
    vadHandler.onSpeechEnd.listen((_) {
      _log('VAD onSpeechEnd (but we also do a manual threshold approach)');
      callbackConfig.onVADSpeechEnd?.call();
    });
    vadHandler.onError.listen((err) {
      _log('VAD error: $err');
      callbackConfig.onError?.call('VAD error: $err', false);
    });
  }

  // ------------------------------------------------------------
  // Handling Server Events
  // ------------------------------------------------------------

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
          if (await player.isPlaying()) {
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

          final error = ServerError(
            code: code.toString(),
            message: message,
            isFatal: isFatal,
          );

          callbackConfig.onError?.call(error.readableMessage, error.isFatal);
          if (isFatal) {
            _log('Fatal => cleaning up...');
            await disconnect();
            callbackConfig.onHangup?.call(HangUpReason.error);
          }
          throw error;

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
      if (e is AgentException) {
        rethrow;
      }
      throw ServerError(
        code: 'parse_error',
        message: 'Failed to parse server event: $e',
        isFatal: false,
      );
    }
  }

  // ------------------------------------------------------------
  // Sending Events from the Client to the Agent
  // ------------------------------------------------------------

  /// Adds a payload to the WebSocket sink if the agent is connected.
  void _sendPayload(Map<String, dynamic> payload) {
    if (!isConnected) {
      throw const NoConversationInProgress();
    }
    try {
      ws?.sink.add(jsonEncode(payload));
    } catch (e) {
      _log('Error sending payload: $e');
      throw WebSocketConnectionError(e.toString());
    }
  }

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
    _sendPayload(setup);
  }

  /// Declares the actions that the agent can perform after the setup message.
  void _sendActionsMessage() {
    if (actions.isEmpty) return;
    final message = <String, dynamic>{
      'type': 'extendConversationSetup',
      'events': actions.map((e) => e.toAgentInstructions()).toList(),
    };
    _sendPayload(message);
  }

  /// Sends {type:'bufferEmpty'} when the player's buffer is empty.
  void _sendBufferEmptyEvent() {
    final msg = <String, dynamic>{'type': 'bufferEmpty'};
    _sendPayload(msg);
  }

  /// Sends audioIn payload to the agent.
  void _sendAudioIn(String data) {
    final payload = {'type': 'audioIn', 'data': data};
    _sendPayload(payload);
  }

  /// Sends a short base64 mu-law silence chunk if the user is muted.
  void _sendAudioInAsSilence() {
    final payload = {'type': 'audioIn', 'data': base64MuLawDataForSilence};
    _sendPayload(payload);
  }

  /// Sends a custom input to the agent.
  void _sendCustomInput(String data) {
    final message = <String, dynamic>{'type': 'customInput', 'data': data};
    _sendPayload(message);
  }

  @override
  Future<void> sendDeveloperMessage(String message) async {
    if (!isConnected) {
      throw const NoConversationInProgress();
    }
    _log('Sending developer message to agent: $message');
    _sendCustomInput(message);
  }
}
