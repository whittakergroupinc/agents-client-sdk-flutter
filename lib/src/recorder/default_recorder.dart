import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as record;

import 'recorder_base.dart';

abstract class _RecorderImpl implements RecorderBase {
  _RecorderImpl({this.onFrameRecorded});

  @override
  Future<bool> hasPermission() => Permission.microphone.request().isGranted;

  final void Function(List<int> frame)? onFrameRecorded;
  StreamSubscription<List<int>>? _subscription;

  Future<Stream<List<int>>> _startStream();

  @override
  Future<Stream<List<int>>> startStream() async {
    final stream = (await _startStream()).asBroadcastStream();
    _subscription = stream.listen(onFrameRecorded);
    return stream;
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    _subscription?.cancel();
    return;
  }
}

final class AudioRecorder extends _RecorderImpl {
  AudioRecorder({super.onFrameRecorded});

  static const _audioConfig = record.RecordConfig(
    encoder: record.AudioEncoder.pcm16bits,
    sampleRate: 16000,
    bitRate: 16,
    numChannels: 1,
    echoCancel: true,
    autoGain: true,
    noiseSuppress: true,
    iosConfig: record.IosRecordConfig(
      manageAudioSession: false,
      categoryOptions: [
        record.IosAudioCategoryOption.mixWithOthers,
        record.IosAudioCategoryOption.allowBluetooth,
        record.IosAudioCategoryOption.allowBluetoothA2DP,
        record.IosAudioCategoryOption.allowAirPlay,
        record.IosAudioCategoryOption.defaultToSpeaker,
      ],
    ),
  );

  final _recorder = record.AudioRecorder();

  @override
  Future<Stream<List<int>>> _startStream() {
    return _recorder.startStream(_audioConfig);
  }

  @override
  Future<void> pauseStream() {
    return _recorder.pause();
  }

  @override
  Future<void> resumeStream() {
    return _recorder.resume();
  }

  @override
  Future<void> stopStream() {
    return _recorder.stop();
  }

  @override
  Future<void> dispose() {
    _recorder.dispose();
    return super.dispose();
  }
}
