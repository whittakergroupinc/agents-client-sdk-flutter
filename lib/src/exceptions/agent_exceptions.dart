sealed class AgentException implements Exception {
  const AgentException(this.code, this.readableMessage);

  final String code;
  final String readableMessage;
}

class NoConversationInProgress extends AgentException {
  const NoConversationInProgress()
      : super('no_conversation_in_progress', 'No conversation is in progress.');
}

class AgentConnectionError extends AgentException {
  const AgentConnectionError()
      : super('agent_connection_error', 'Failed to connect to the agent.');
}
