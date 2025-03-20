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

/// {@template agent}
/// A voice-powered conversational agent that can perform custom actions.
///
/// The agent handles:
/// - Two-way voice communication
/// - Voice activity detection (VAD)
/// - Audio session management
/// - Custom action execution
///
/// Example usage within a widget:
/// ```dart
/// class VoiceAgentWidget extends StatefulWidget {
///   @override
///   State<VoiceAgentWidget> createState() => _VoiceAgentWidgetState();
/// }
///
/// class _VoiceAgentWidgetState extends State<VoiceAgentWidget> {
///   Agent? _agent;
///   bool _isConnected = false;
///
///   @override
///   void initState() {
///     super.initState();
///     _setupAgent();
///   }
///
///   void _setupAgent() {
///     _agent = Agent(
///       // Get your agent ID from play.ai
///       agentId: 'your-agent-id',
///       // Customize the agent's behavior
///       prompt: 'You are a helpful assistant.',
///       // Define custom actions the agent can perform
///       actions: [
///         AgentAction(
///           name: 'greet_user',
///           triggerInstructions: 'Trigger this when user asks for a greeting',
///           argumentSchema: {
///             'name': AgentActionParameter(
///               type: 'string',
///               description: 'The name of the user to greet',
///             ),
///           },
///           callback: (data) async {
///             final name = data['name'] as String;
///             return 'Hello, $name!';
///           },
///         ),
///       ],
///       // Configure callbacks for agent events
///       callbackConfig: AgentCallbackConfig(
///         onUserTranscript: (text) => print('User said: $text'),
///         onAgentTranscript: (text) => print('Agent said: $text'),
///         onError: (error, isFatal) => print('Error: $error'),
///       ),
///     );
///   }
///
///   Future<void> _toggleConnection() async {
///     try {
///       if (_isConnected) {
///         await _agent?.disconnect();
///       } else {
///         await _agent?.connect();
///       }
///       setState(() => _isConnected = !_isConnected);
///     } catch (e) {
///       print('Error toggling connection: $e');
///     }
///   }
///
///   @override
///   void dispose() {
///     _agent?.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ElevatedButton(
///           onPressed: _toggleConnection,
///           child: Text(_isConnected ? 'Disconnect' : 'Connect'),
///         ),
///         Text('Status: ${_isConnected ? 'Connected' : 'Disconnected'}'),
///       ],
///     );
///   }
/// }
/// ```
///
/// To use the agent:
/// 1. Create an agent on play.ai to get an agent ID
/// 2. Initialize the [Agent] with your agent ID and configuration
/// 3. Connect to start a conversation using [connect()]
/// 4. Define custom actions using [AgentAction]s
/// 5. Handle agent events through [AgentCallbackConfig]
/// 6. Disconnect when done using [disconnect()]
/// 7. Dispose of resources using [dispose()]
///
/// The agent handles several types of errors:
/// - [InvalidAgentState]: When operations are attempted in wrong states
/// - [NoConversationInProgress]: When trying to use agent before connecting
/// - [PermissionException]: When required permissions are denied
/// - [ConnectionException]: When WebSocket connection fails
/// - [AudioSessionException]: When audio session setup fails
/// - [AudioPlayerException]: When audio playback fails
/// - [ServerException]: When server returns errors
/// - [VadException]: When voice activity detection fails
///
/// All errors are subclasses of [AgentException], which is a sealed class.
/// {@endtemplate}
abstract interface class Agent {
  /// Create a voice-powered conversational agent.
  ///
  /// {@macro agent}
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

  /// Base URL for the agent API.
  ///
  /// Defaults to 'wss://api.play.ai'. Only change this if you're using a custom endpoint.
  String get baseUrl;

  /// The unique identifier for this agent.
  ///
  /// Obtain this ID by creating a new agent on play.ai. This ID determines the agent's
  /// personality and capabilities.
  String get agentId;

  /// Configuration for various agent callbacks and debug options.
  ///
  /// Use this to handle agent events like transcripts, audio state changes,
  /// and errors. Example:
  /// ```dart
  /// AgentCallbackConfig(
  ///   onUserTranscript: (text) => print('User said: $text'),
  ///   onAgentTranscript: (text) => print('Agent said: $text'),
  ///   debug: true, // Enables detailed logging
  /// )
  /// ```
  AgentCallbackConfig get callbackConfig;

  /// The system prompt that defines the agent's behavior.
  ///
  /// This prompt sets the context and personality for the agent. Example:
  /// ```dart
  /// "You are a helpful assistant who speaks in a friendly, casual tone.
  ///  You help users with their tasks and questions."
  /// ```
  String get prompt;

  /// List of custom actions that the agent can perform.
  ///
  /// These actions allow the agent to interact with your application. Example:
  /// ```dart
  /// [
  ///   AgentAction(
  ///     name: 'change_theme',
  ///     triggerInstructions: 'Trigger this when user wants to change the app theme',
  ///     argumentSchema: {
  ///       'isDark': AgentActionParameter(
  ///         type: 'boolean',
  ///         description: 'Whether to switch to dark theme',
  ///       ),
  ///     },
  ///     callback: (data) async {
  ///       final isDark = data['isDark'] as bool;
  ///       // Implementation to change theme
  ///       return 'Theme changed successfully';
  ///     },
  ///   ),
  /// ]
  /// ```
  List<AgentAction> get actions;

  /// The audio player responsible for playing the agent's voice.
  ///
  /// This player handles the audio output stream from the agent.
  /// You can provide a custom implementation by implementing [AudioPlayerBase].
  AudioPlayerBase get player;

  /// The Voice Activity Detection (VAD) handler.
  ///
  /// Detects when the user is speaking and manages audio input.
  VadHandlerBase get vadHandler;

  /// Manages the audio session for the agent.
  ///
  /// Handles audio routing, interruptions, and device changes.
  /// The default implementation is [AudioSessionManager].
  /// You can provide a custom implementation by implementing [AudioSessionManagerBase].
  AudioSessionManagerBase get audioSessionManager;

  /// Notifies about the current conversation ID.
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<String?>(
  ///     valueListenable: agent.conversationIdNotifier,
  ///     builder: (context, conversationId, child) {
  ///       return Text('Conversation: ${conversationId ?? 'None'}');
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<String?> get conversationIdNotifier;

  /// Notifies about the agent's current state.
  ///
  /// States: idle, connecting, connected, disconnecting
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<AgentState>(
  ///     valueListenable: agent.stateNotifier,
  ///     builder: (context, state, child) {
  ///       return Text('Agent State: $state');
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<AgentState> get stateNotifier;

  /// Notifies about the agent's connection status.
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<bool>(
  ///     valueListenable: agent.isConnectedNotifier,
  ///     builder: (context, isConnected, child) {
  ///       return Icon(
  ///         isConnected ? Icons.cloud_done : Icons.cloud_off,
  ///         color: isConnected ? Colors.green : Colors.red,
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<bool> get isConnectedNotifier;

  /// Notifies about the microphone mute status.
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<bool>(
  ///     valueListenable: agent.isMutedNotifier,
  ///     builder: (context, isMuted, child) {
  ///       return IconButton(
  ///         icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
  ///         onPressed: () => isMuted ? agent.unmute() : agent.mute(),
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<bool> get isMutedNotifier;

  /// Notifies when the agent is speaking.
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<bool>(
  ///     valueListenable: agent.isAgentSpeakingNotifier,
  ///     builder: (context, isSpeaking, child) {
  ///       return AnimatedContainer(
  ///         duration: Duration(milliseconds: 200),
  ///         width: isSpeaking ? 40.0 : 20.0,
  ///         height: isSpeaking ? 40.0 : 20.0,
  ///         decoration: BoxDecoration(
  ///           color: isSpeaking ? Colors.blue : Colors.grey,
  ///           shape: BoxShape.circle,
  ///         ),
  ///         child: Icon(Icons.record_voice_over),
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<bool> get isAgentSpeakingNotifier;

  /// Notifies when the user is speaking.
  ///
  /// Example usage in a widget:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ValueListenableBuilder<bool>(
  ///     valueListenable: agent.isUserSpeakingNotifier,
  ///     builder: (context, isSpeaking, child) {
  ///       return AnimatedContainer(
  ///         duration: Duration(milliseconds: 200),
  ///         padding: EdgeInsets.all(8),
  ///         decoration: BoxDecoration(
  ///           color: isSpeaking ? Colors.green.withOpacity(0.2) : Colors.transparent,
  ///           borderRadius: BorderRadius.circular(8),
  ///         ),
  ///         child: Text(
  ///           isSpeaking ? 'Listening...' : 'Waiting for input...',
  ///           style: TextStyle(
  ///             color: isSpeaking ? Colors.green : Colors.grey,
  ///           ),
  ///         ),
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  ValueListenable<bool> get isUserSpeakingNotifier;

  /// Connect to the agent in a new conversation.
  ///
  /// Throws:
  /// - [InvalidAgentState] if the agent is not in idle state
  /// - [MicrophonePermissionDenied] if microphone permission is not granted
  /// - [BluetoothPermissionDenied] if Bluetooth permissions are denied on Android
  /// - [WebSocketConnectionError] if connection to the agent fails
  /// - [AudioSessionError] if audio session fails to start
  Future<void> connect();

  /// Mute the user's microphone in the current conversation.
  ///
  /// Throws:
  /// - [NoConversationInProgress] if there is no active conversation
  Future<void> muteUser();

  /// Unmute the user's microphone in the current conversation.
  ///
  /// Throws:
  /// - [NoConversationInProgress] if there is no active conversation
  Future<void> unmuteUser();

  /// Sends a custom context message to the agent during an active conversation.
  ///
  /// This method allows developers to inject custom context or information into
  /// the conversation at any time. This is useful for:
  ///
  /// 1. Informing the agent about app state changes:
  /// ```dart
  /// // When navigation occurs
  /// void _onRouteChanged(String newRoute) {
  ///   agent.sendDeveloperMessage(
  ///     'User navigated to $newRoute. You can now discuss content specific to this screen.',
  ///   );
  /// }
  ///
  /// // When theme changes
  /// void _onThemeChanged(bool isDark) {
  ///   agent.sendDeveloperMessage(
  ///     'App theme changed to ${isDark ? "dark" : "light"} mode. You can acknowledge this change if the user mentions it.',
  ///   );
  /// }
  /// ```
  ///
  /// 2. Updating the agent about dynamic content:
  /// ```dart
  /// // When new data loads
  /// void _onDataLoaded(List<Product> products) {
  ///   agent.sendDeveloperMessage(
  ///     'New products available: ${products.map((p) => p.name).join(", ")}. '
  ///     'You can now discuss these specific products.',
  ///   );
  /// }
  /// ```
  ///
  /// 3. Providing real-time context:
  /// ```dart
  /// // During error states
  /// void _onError(String error) {
  ///   agent.sendDeveloperMessage(
  ///     'User encountered an error: $error. '
  ///     'Please acknowledge this and provide guidance if they ask about it.',
  ///   );
  /// }
  ///
  /// // For user preferences
  /// void _onPreferencesChanged(UserPreferences prefs) {
  ///   agent.sendDeveloperMessage(
  ///     'User preferences updated: language=${prefs.language}, '
  ///     'notifications=${prefs.notificationsEnabled}. '
  ///     'Adjust your responses accordingly.',
  ///   );
  /// }
  /// ```
  ///
  /// The message should be clear and instructive, as it becomes part of the agent's
  /// context for future responses. The agent will maintain this context until the
  /// conversation ends.
  ///
  /// Throws:
  /// - [NoConversationInProgress] if there is no active conversation
  Future<void> sendDeveloperMessage(String message);

  /// Forcibly end the current conversation.
  ///
  /// Throws:
  /// - [NoConversationInProgress] if there is no active conversation
  Future<void> disconnect();

  /// Dispose of the agent and free up resources.
  ///
  /// This will also end the current conversation, and no more conversations
  /// can be started with this instance.
  ///
  /// Throws:
  /// - [AudioPlayerError] if there is an error disposing the audio player
  Future<void> dispose();
}
