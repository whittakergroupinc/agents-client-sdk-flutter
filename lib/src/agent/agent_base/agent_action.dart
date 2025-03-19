part of 'agent_base.dart';

class AgentAction {
  const AgentAction({
    required this.name,
    required this.triggerInstructions,
    required this.argumentSchema,
    required this.callback,
  });

  /// The name of the action.
  final String name;

  /// The instructions for when the action should be triggered.
  final String triggerInstructions;

  /// The schema of the data that the action expects.
  final Map<String, AgentActionParameter> argumentSchema;

  /// The callback to be called when the action is triggered.
  /// Returns a string to be sent back to the agent if needed. Otherwise, return null.
  final FutureOr<String?> Function(Map<String, dynamic> data) callback;

  Map<String, dynamic> toAgentInstructions() {
    return {
      'name': name,
      'when': triggerInstructions,
      'data': argumentSchema.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  @override
  String toString() {
    return 'AgentAction(name: $name, triggerInstructions: $triggerInstructions, argumentSchema: $argumentSchema, callback: $callback)';
  }
}

@immutable
class AgentActionParameter {
  const AgentActionParameter({
    required this.type,
    required this.description,
  });

  /// The type of the argument.
  ///
  /// One of 'string', 'number', 'boolean'.
  final String type;

  /// A description of the argument.
  final String description;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'description': description,
    };
  }

  @override
  String toString() =>
      'AgentActionParameter(type: $type, description: $description)';

  @override
  bool operator ==(covariant AgentActionParameter other) {
    if (identical(this, other)) return true;

    return other.type == type && other.description == description;
  }

  @override
  int get hashCode => type.hashCode ^ description.hashCode;
}
