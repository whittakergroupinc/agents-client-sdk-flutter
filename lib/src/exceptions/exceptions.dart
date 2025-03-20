import '../agent/interfaces/interfaces.dart';

part 'audio_player_exceptions.dart';
part 'audio_session_exceptions.dart';
part 'connection_exceptions.dart';
part 'permission_exceptions.dart';
part 'server_exceptions.dart';
part 'vad_exceptions.dart';

/// Base class for all agent-related exceptions.
sealed class AgentException implements Exception {
  const AgentException(this.code, this.readableMessage);

  /// A machine-readable error code
  final String code;

  /// A human-readable error message
  final String readableMessage;
}

/// Thrown when trying to perform operations on a conversation that doesn't exist.
///
/// This can happen when:
/// - Trying to disconnect when no conversation is in progress
/// - Trying to send messages when not connected
/// - Trying to mute/unmute when not connected
final class NoConversationInProgress extends AgentException {
  const NoConversationInProgress()
      : super('no_conversation_in_progress', 'No conversation is in progress.');
}

/// Thrown when the agent is in an invalid state for the requested operation.
///
/// This can happen when:
/// - Trying to connect when already connected or connecting
/// - Trying to perform operations while disconnecting
final class InvalidAgentState extends AgentException {
  const InvalidAgentState(AgentState currentState, String operation)
      : super(
          'invalid_agent_state',
          'Cannot $operation: Agent is in $currentState state',
        );
}
