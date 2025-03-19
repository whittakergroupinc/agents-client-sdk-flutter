// VAD handler
// Adapted from https://github.com/keyur2maru/vad/blob/master/lib/src/vad_handler.dart

import '../../recorder/recorder_base.dart';
import 'vad_handler_base.dart';
import 'vad_handler_web.dart' if (dart.library.io) 'vad_handler_non_web.dart'
    as implementation;

class VadHandler {
  /// Create a new instance of VadHandler.
  static VadHandlerBase create({
    required bool isDebug,
    RecorderBase? nonWebRecorder,
  }) {
    return implementation.createVadHandler(
      isDebug: isDebug,
      recorder: nonWebRecorder,
    );
  }
}
