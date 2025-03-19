import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

import 'audio_player.dart';

/// The default implementation of [AudioPlayerBase].
///
/// Uses [FlutterSoundPlayer] to play PCM16 encoded audio data.
class AudioPlayer implements AudioPlayerBase {
  AudioPlayer({this.onEmptyQueue});

  @override
  final VoidCallback? onEmptyQueue;

  FlutterSoundPlayer? player;

  final chunkQueue = Queue<Uint8List>();
  bool feedingInProgress = false;

  @override
  bool isPlaying() => player != null && player!.isOpen() && player!.isPlaying;

  @override
  Stream<bool> get playingStream =>
      player?.onProgress?.map((pos) => isPlaying()) ?? Stream.value(false);

  Future<void> _startPlayer() =>
      player?.startPlayerFromStream(
        sampleRate: 44100,
        interleaved: true,
        codec: Codec.pcm16,
        numChannels: 1,
        bufferSize: 8192,
      ) ??
      Future.value();

  @override
  Future<void> initialize() async {
    player = await FlutterSoundPlayer(logLevel: Level.error).openPlayer();
    await player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    return _startPlayer();
  }

  @override
  Future<void> stop() {
    chunkQueue.clear();
    feedingInProgress = false;
    return player?.stopPlayer() ?? Future.value();
  }

  @override
  Future<void> advance() async {
    await stop();
    return _startPlayer();
  }

  @override
  Future<void> feed(Uint8List chunk) {
    chunkQueue.add(chunk);
    return _feedNextChunk();
  }

  Future<void> _feedNextChunk() async {
    final player = this.player;
    if (player == null) return;
    if (feedingInProgress) return;
    if (chunkQueue.isEmpty) return;

    feedingInProgress = true;
    while (chunkQueue.isNotEmpty) {
      if (!feedingInProgress) return;
      final chunk = chunkQueue.removeFirst();
      try {
        await player.feedUint8FromStream(chunk);
      } catch (e) {
        debugPrint('Error feeding chunk: $e');
        break;
      }
    }
    debugPrint('Feeding complete');
    onEmptyQueue?.call();
    feedingInProgress = false;
  }

  @override
  Future<void> pause() => player?.pausePlayer() ?? Future.value();

  @override
  Future<void> resume() => player?.resumePlayer() ?? Future.value();

  @override
  Future<void> dispose() async {
    await player?.closePlayer();
    player = null;
    return;
  }
}
