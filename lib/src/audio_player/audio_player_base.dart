import 'dart:async';

import 'package:flutter/foundation.dart';

abstract interface class AudioPlayerBase {
  const AudioPlayerBase();

  Stream<bool> get playingStream;
  VoidCallback? get onEmptyQueue;

  Future<void> init();
  Future<void> dispose();
  Future<void> feed(Uint8List chunk);
  Future<void> advance();
  Future<void> pause();
  Future<void> resume();

  FutureOr<bool> isPlaying();
}
