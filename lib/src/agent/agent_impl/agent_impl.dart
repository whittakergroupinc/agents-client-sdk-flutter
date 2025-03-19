import 'dart:async';
import 'dart:convert' hide Codec;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../audio_player/audio_player.dart';
import '../../audio_session_manager/audio_session_manager.dart';
import '../../exceptions/exceptions.dart';
import '../../recorder/recorder.dart';
import '../../vad/vad.dart';
import '../agent.dart';

part 'audio_session_events.dart';
part 'client_events.dart';
part 'server_events.dart';
part 'vad_events.dart';

final class AgentBase extends _AgentImpl
    with _AudioSessionEvents, _ClientEvents, _ServerEvents, _VadEvents {
  AgentBase({
    required super.agentId,
    required super.prompt,
    required super.actions,
    required super.audioSessionManager,
    required super.callbackConfig,
    required super.recorder,
    required super.player,
  }) {
    _createVadHandler();
  }

  @override
  WebSocketChannel? ws;

  StreamSubscription<bool>? playerSubscription;

  Future<void> _initializeAudioPlayer() async {
    player.onEmptyQueue = _sendBufferEmptyEvent;
    await player.initialize();
    // Listen to player states to detect agent's start/stop speaking
    playerSubscription = player.playingStream.listen((isPlaying) {
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
    });
    return;
  }

  Future<void> _connectWebSocket() async {
    assert(ws == null, 'WebSocket already connected!');
    _log('Connecting WebSocket to the agent...');
    final wsUrl = Uri.parse(
      'wss://staging.api.play.ai'
      // 'ws://localhost:4400'
      '/v1/agents/$agentId/start-conversation',
    );
    try {
      ws = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: const Duration(seconds: 10),
      );
      _log('WebSocket connected');
    } catch (e) {
      _log('Failed to connect WebSocket: $e');
      rethrow;
    }
  }

  @override
  Future<void> connect() async {
    if (state != AgentState.idle) {
      throw StateError('Cannot connect: Agent is in $state state');
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
        throw Exception('Failed to create audio session');
      }

      stateNotifier.value = AgentState.connected;

      return;
    } catch (e) {
      _log('Error during connect: $e');
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (state == AgentState.idle) throw const NoConversationInProgress();
    if (state == AgentState.disconnecting) return; // Already disconnecting

    stateNotifier.value = AgentState.disconnecting;

    await super.disconnect();

    try {
      _log('resetting agent...');
      await ws?.sink.close();
      await wsSubscription?.cancel();
      await player.stop();
      playerSubscription?.cancel();
    } catch (e) {
      _log('Error during reset: $e');
    } finally {
      _log('Agent reset');
      ws = null;
      wsSubscription = null;
      playerSubscription = null;
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
    return;
  }
}

abstract final class _AgentImpl implements Agent {
  _AgentImpl({
    required this.agentId,
    required this.prompt,
    required this.actions,
    required AudioSessionManagerBase? audioSessionManager,
    required this.callbackConfig,
    required RecorderBase? recorder,
    required AudioPlayerBase? player,
  }) {
    _audioSessionManager = audioSessionManager;
    _player = player;
    _recorder = recorder;
  }

  @override
  final String agentId;

  @override
  final String prompt;

  @override
  final List<AgentAction> actions;

  @override
  final AgentCallbackConfig callbackConfig;

  late final AudioSessionManagerBase? _audioSessionManager;
  late final RecorderBase? _recorder;
  late final AudioPlayerBase? _player;

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

  void _log(String message) {
    if (callbackConfig.debug) {
      // ignore: avoid_print
      print('[AGENT] $message');
    }
  }

  @override
  Future<void> mute() async {
    if (isMuted) return;
    isMutedNotifier.value = true;
    _log('User mic muted => sending silence');
  }

  @override
  Future<void> unmute() async {
    if (!isMuted) return;
    isMutedNotifier.value = false;
    _log('User mic unmuted');
  }

  @override
  @mustCallSuper
  Future<void> disconnect() async {
    _log('Disconnecting...');
    callbackConfig.onHangup?.call(HangUpReason.user);
    isConnectedNotifier.value = false;
    isUserSpeakingNotifier.value = false;
    isAgentSpeakingNotifier.value = false;
    isMutedNotifier.value = false;
    stateNotifier.value = AgentState.idle;
    return;
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await disconnect();
    stateNotifier.dispose();
    isConnectedNotifier.dispose();
    isMutedNotifier.dispose();
    isAgentSpeakingNotifier.dispose();
    isUserSpeakingNotifier.dispose();
  }
}
