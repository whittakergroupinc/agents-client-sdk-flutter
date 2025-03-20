# PlayAI Agents SDK for Flutter

[![pub package](https://img.shields.io/pub/v/agents.svg)](https://pub.dev/packages/agents)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Voice-powered AI agents made easy. The official Agents Client SDK for Flutter by [Play.AI](https://play.ai/).

## 🚀 Features

- 🎙️ **Two-way voice conversations** with AI agents
- 🔊 **Voice Activity Detection (VAD)** for natural conversations
- 🧠 **Custom actions** that allow agents to trigger code in your app
- 📱 **Cross-platform** - works on iOS, Android, and Web
- 🔌 **Audio session management** for handling interruptions and device changes
- 📝 **Real-time transcripts** of both user and agent speech
- 🚦 **Rich state management** with ValueNotifiers for UI integration

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  agents: ^0.0.1-alpha.1
```

Then save, or run:

```bash
flutter pub get
```

### Platform Configuration

#### iOS

1. Add the following to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to enable voice conversations with the AI agent.</string>
```

2. Add the following to your `Podfile`, since we depend on `permission_handler` to manage permissions and `audio_session` to manage audio sessions.

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        # audio_session settings
        'AUDIO_SESSION_MICROPHONE=0',
        # For microphone access
        'PERMISSION_MICROPHONE=1'
    end
  end
end
```

3. Due to an [issue](https://github.com/gtbluesky/onnxruntime_flutter/issues/24) of the Onnx Runtime getting stripped by XCode when archived, you need to follow these steps in XCode for the voice activity detector (VAD) to work on iOS builds:
    - Under "Targets", choose "Runner" (or your project's name)
    - Go to "Build Settings" tab
    - Filter for "Deployment"
    - Set "Stripped Linked Product" to "No"
    - Set "Strip Style" to "Non-Global-Symbols"


#### Android

1. Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. Add the following to `android/gradle.properties` (unless they're already there):

```
android.useAndroidX=true
android.enableJetifier=true
```

3. Add the following settings to `android/app/build.gradle`:

```
android {
    compileSdkVersion 34
    ...
}
```

#### Web

For VAD to work on web platforms, please following the instructions [here](https://pub.dev/packages/vad#web).

## 🔰 Getting Started

### 1. Create an Agent on Play.AI

1. Sign up at [Play.AI](https://play.ai/).
2. Create a new agent [here](https://play.ai/my-agents) and get your agent ID.

### 2. Implement the Agent in Your Flutter App

```dart
import 'package:agents/agents.dart';
import 'package:flutter/material.dart';

class VoiceAgentPage extends StatefulWidget {
  @override
  State<VoiceAgentPage> createState() => _VoiceAgentPageState();
}

class _VoiceAgentPageState extends State<VoiceAgentPage> {
  Agent? _agent;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupAgent();
  }

  void _setupAgent() {
    _agent = Agent(
      // Replace with your agent ID from Play.AI
      agentId: 'your-agent-id-here',
      // Customize your agent's behavior
      prompt: 'You are a helpful assistant who speaks in a friendly, casual tone.',
      // Define actions the agent can take in your app
      actions: [
        AgentAction(
          name: 'show_weather',
          triggerInstructions: 'Trigger this when the user asks about weather.',
          argumentSchema: {
            'city': AgentActionParameter(
              type: 'string',
              description: 'The city to show weather for',
            ),
          },
          callback: (data) async {
            final city = data['city'] as String;
            // In a real app, you would fetch weather data here
            return 'Weather data fetched for $city!';
          },
        ),
      ],
      // Configure callbacks to respond to agent events
      callbackConfig: AgentCallbackConfig(
        // Get user speech transcript
        onUserTranscript: (text) {
          setState(() => _messages.add(ChatMessage(text, isUser: true)));
        },
        // Get agent speech transcript
        onAgentTranscript: (text) {
          setState(() => _messages.add(ChatMessage(text, isUser: false)));
        },
        // Handle any errors
        onError: (error, isFatal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      ),
    );
  }

  Future<void> _toggleConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_agent?.isConnected ?? false) {
        await _agent?.disconnect();
      } else {
        await _agent?.connect();
      }
      if (mounted) setState(() {});
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _agent?.dispose(); // Properly clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = _agent;
    if (agent == null) return const CircularProgressIndicator();

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Agent Demo')),
      body: Column(
        children: [
          // Status indicators
          _buildStatusIndicators(agent),
          // Messages list
          Expanded(child: _buildMessagesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleConnection,
        child: ValueListenableBuilder<bool>(
          valueListenable: agent.isConnectedNotifier,
          builder: (context, isConnected, _) => Icon(
            isConnected ? Icons.call_end : Icons.call,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(Agent agent) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Connection status
          ValueListenableBuilder<bool>(
            valueListenable: agent.isConnectedNotifier,
            builder: (context, isConnected, _) => Chip(
              label: Text(isConnected ? 'Connected' : 'Disconnected'),
              backgroundColor: isConnected ? Colors.green.shade100 : Colors.grey.shade300,
            ),
          ),
          // Mute status
          ValueListenableBuilder<bool>(
            valueListenable: agent.isMutedNotifier,
            builder: (context, isMuted, _) => IconButton(
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
              onPressed: () => isMuted ? agent.unmute() : agent.mute(),
            ),
          ),
          // Agent speaking status
          ValueListenableBuilder<bool>(
            valueListenable: agent.isAgentSpeakingNotifier,
            builder: (context, isSpeaking, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSpeaking ? Colors.blue.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.record_voice_over,
                color: isSpeaking ? Colors.blue.shade800 : Colors.grey,
              ),
            ),
          ),
          // User speaking status
          ValueListenableBuilder<bool>(
            valueListenable: agent.isUserSpeakingNotifier,
            builder: (context, isSpeaking, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSpeaking ? Colors.green.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.mic,
                color: isSpeaking ? Colors.green.shade800 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      itemCount: _messages.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Align(
          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blue.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(message.text),
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage(this.text, {required this.isUser});
}
```

## 🧩 Key Components

### Agent Class

The main interface for interacting with PlayAI voice agents.

```dart
final agent = Agent(
  agentId: 'your-agent-id-here',
  prompt: 'You are a helpful assistant.',
  actions: [ /* custom actions */ ],
  callbackConfig: AgentCallbackConfig( /* callbacks */ ),
);
```

### AgentState

The agent can be in one of four states:

- `idle`: Not connected to a conversation
- `connecting`: In the process of establishing a connection
- `connected`: Connected and ready to converse
- `disconnecting`: In the process of ending a conversation

### Agent Actions

One of the most exciting features of the PlayAI Agents SDK is the ability to define custom actions that allow the agent to interact with your app.

```dart
AgentAction(
  name: 'open_settings',
  triggerInstructions: 'Trigger this when the user asks to open settings',
  argumentSchema: {
    'section': AgentActionParameter(
      type: 'string',
      description: 'The settings section to open',
    ),
  },
  callback: (data) async {
    final section = data['section'] as String;
    // Navigate to settings section in your app
    return 'Opened $section settings';
  },
)
```

### State Monitoring

Monitor agent states with `ValueListenable`s:

```dart
ValueListenableBuilder<AgentState>(
  valueListenable: agent.stateNotifier,
  builder: (context, state, _) => Text('Agent state: $state'),
)
```

### Developer Messages

Send contextual information to the agent during a conversation to inform it of changes in your app.

```dart
// When user navigates to a new screen
void _onNavigate(String routeName) {
  agent.sendDeveloperMessage(
    'User navigated to $routeName screen. You can now discuss the content on this page.',
  );
}

// When relevant data changes
void _onCartUpdated(List<Product> products) {
  agent.sendDeveloperMessage(
    'User\'s cart has been updated, now containing: ${products.map((p) => p.name).join(", ")}.',
  );
}
```

## 🛡️ Error Handling

The package uses a robust error handling system with specific exception types:

```dart
try {
  await agent.connect();
} on MicrophonePermissionDenied {
  // Handle microphone permission issues
} on WebSocketConnectionError catch (e) {
  // Handle connection issues
} on ServerError catch (e) {
  // Handle server-side errors
  if (e.isFatal) {
    // Handle fatal errors
  }
} on AgentException catch (e) {
  // Handle all other agent exceptions
  print('Error code: ${e.code}, Message: ${e.readableMessage}');
}
```

## 🔄 Lifecycle Management

Don't forget to dispose of the agent when it's no longer needed to free up resources.

```dart
@override
void dispose() {
  // Clean up resources
  agent.dispose();
  super.dispose();
}
```

## 📱 UI Integration Examples

### Mute Button

```dart
ValueListenableBuilder<bool>(
  valueListenable: agent.isMutedNotifier,
  builder: (context, isMuted, _) => IconButton(
    icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
    onPressed: () => isMuted ? agent.unmute() : agent.mute(),
    tooltip: isMuted ? 'Unmute' : 'Mute',
  ),
)
```

### Speaking Indicator

```dart
ValueListenableBuilder<bool>(
  valueListenable: agent.isAgentSpeakingNotifier,
  builder: (context, isSpeaking, _) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isSpeaking ? Colors.blue : Colors.grey.shade300,
    ),
    child: Center(
      child: Icon(
        Icons.record_voice_over,
        size: 24,
        color: Colors.white,
      ),
    ),
  ),
)
```

## 📢 Tips for Effective Usage

1. **Prompt Engineering**: Craft clear, specific prompts to guide agent behavior
2. **Action Design**: Design actions with clear trigger instructions and parameter descriptions
3. **Context Management**: Use `sendDeveloperMessage` to keep the agent updated on app state
4. **Error Handling**: Implement comprehensive error handling for a smooth user experience
5. **UI Feedback**: Use the provided `ValueListenable`s to give clear feedback on conversation state

## 📜 License

This SDK is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Developed by [Play.AI](https://play.ai/)
- Voice Activity Detection powered by [vad](https://pub.dev/packages/vad)
- Audio session management by [audio_session](https://pub.dev/packages/audio_session)
