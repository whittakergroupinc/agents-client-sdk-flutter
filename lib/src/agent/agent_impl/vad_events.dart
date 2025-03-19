part of 'agent_impl.dart';

base mixin _VadEvents on _ServerEvents {
  late final AudioRecorder audioStreamer = AudioRecorder(
    onFrameRecorded: callbackConfig.onAudioStreamerFrameRecorded,
  );
  late final VadHandlerBase vadHandler =
      VadHandler.create(isDebug: false, nonWebRecorder: audioStreamer);

  Timer? _pauseTimer;

  Future<void> _ensureMicrophonePermission() async {
    final permissionStatus = await Permission.microphone.request();
    _log('Microphone permission: $permissionStatus');
    if (!permissionStatus.isGranted) {
      throw Exception('Microphone permission not granted!');
    }
  }

  void _createVadHandler() {
    // 8) Hook up VAD:
    //    - threshold of 0.85
    //    - a 1s pause to confirm user is done speaking
    void resetPauseTimer() {
      _pauseTimer?.cancel();
      _pauseTimer = Timer(
        const Duration(milliseconds: defaultVadPauseTimeoutMs),
        () {
          // user definitely finished speaking
          if (isUserSpeaking) {
            isUserSpeakingNotifier.value = false;
            _log('User stopped speaking => resume agent audio');
            callbackConfig.onUserStoppedSpeaking?.call();
            player?.resume().catchError((Object? err) {
              _log('Error trying to resume audio: $err');
            });
          }
        },
      );
    }

    vadHandler.onFrameProcessed.listen((frame) {
      callbackConfig.onVADFrameProcessed?.call(frame);
      final ws = this.ws;
      final player = this.player;
      if (ws == null || player == null) {
        _log('Skipping VAD frame: WebSocket or player not initialized');
        return;
      }
      if (!isConnected) {
        // Skip if agent not ready
        return _log('Skipping VAD frame: agent not connected yet.');
      }
      if (isMuted) {
        // Send keep-alive silence
        _sendAudioInAsSilence(ws);
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
          });
        }
        // Reset the "stop speaking" countdown
        resetPauseTimer();
      }

      // Always send frames, even if prob < threshold,
      // because server wants continuous input.
      final encoded = encodeFloat32FrameToMuLaw(frame.frame);
      final b64 = base64.encode(encoded);
      final payload = {'type': 'audioIn', 'data': b64};
      // _log('Sending audioIn => ${payload["data"]?.length} bytes');
      ws.sink.add(jsonEncode(payload));
    });
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

  @override
  @mustCallSuper
  Future<void> disconnect() async {
    await super.disconnect();
    try {
      _pauseTimer?.cancel();
      vadHandler.stopListening();
    } catch (e) {
      rethrow;
    } finally {
      _pauseTimer = null;
    }
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await audioStreamer.dispose();
    vadHandler.dispose();
    await super.dispose();
  }
}
