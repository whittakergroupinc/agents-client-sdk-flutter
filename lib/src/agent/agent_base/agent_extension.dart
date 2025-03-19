part of 'agent_base.dart';

extension AgentUtilsExtension on Agent {
  AgentState get state => stateNotifier.value;
  bool get isConnected => isConnectedNotifier.value;
  bool get isMuted => isMutedNotifier.value;
  bool get isAgentSpeaking => isAgentSpeakingNotifier.value;
  bool get isUserSpeaking => isUserSpeakingNotifier.value;
}
