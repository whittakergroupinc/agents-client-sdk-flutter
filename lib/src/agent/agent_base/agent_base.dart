import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vad/vad.dart';

import '../../audio_player/audio_player.dart';
import '../../audio_session_manager/audio_session_manager.dart';
import '../agent_impl/agent_impl.dart';

part 'agent_action.dart';
part 'agent_callback_config.dart';
part 'agent_extension.dart';
part 'enums.dart';

abstract interface class Agent {
  factory Agent({
    String baseUrl = 'wss://api.play.ai',
    required String agentId,
    String prompt = 'You are a helpful assistant.',
    List<AgentAction> actions = const [],
    AudioSessionManagerBase? audioSessionManager,
    AudioPlayerBase? player,
    AgentCallbackConfig callbackConfig = const AgentCallbackConfig(),
  }) =>
      AgentBase(
        baseUrl: baseUrl,
        agentId: agentId,
        prompt: prompt,
        actions: actions,
        audioSessionManager:
            audioSessionManager ?? AudioSessionManager.defaultConfig(),
        callbackConfig: callbackConfig,
        player: player,
      );

  String get baseUrl;
  String get agentId;
  AgentCallbackConfig get callbackConfig;
  String get prompt;
  List<AgentAction> get actions;

  AudioPlayerBase get player;
  VadHandlerBase get vadHandler;
  AudioSessionManagerBase get audioSessionManager;

  ValueListenable<String?> get conversationIdNotifier;
  ValueListenable<AgentState> get stateNotifier;
  ValueListenable<bool> get isConnectedNotifier;
  ValueListenable<bool> get isMutedNotifier;
  ValueListenable<bool> get isAgentSpeakingNotifier;
  ValueListenable<bool> get isUserSpeakingNotifier;

  /// Connect to the agent in a new conversation.
  Future<void> connect();

  /// Mute the user's microphone in the current conversation.
  Future<void> mute();

  /// Unmute the user's microphone in the current conversation.
  Future<void> unmute();

  /// Send a developer message to the agent in the current conversation.
  Future<void> sendDeveloperMessage(String message);

  /// Forcibly end the current conversation.
  Future<void> disconnect();

  /// Dispose of the agent and free up resources.
  ///
  /// This will also end the current conversation, and no more conversations
  /// can be started with this instance.
  Future<void> dispose();
}
