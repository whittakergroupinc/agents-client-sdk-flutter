

import 'dart:typed_data';

const defaultVadThreshold = 0.85;
const defaultVadPauseTimeoutMs = 500;

const base64MuLawDataForSilence =
    '/f39/fz9/f3+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v///v7+/f39/v7+/v7+/v7/////fn5+fn5+fn5+fn5+f/9/fn////////9/fn5+fn5+fn19fX19fn19fX1+fn5+fn5+fn5+fn5////+/v7+/v7+/v7+/v///35+fn5+fn5+fn5+fn5+fn7/fn7//////v7+/v7/////////f35+fn5+fn5+fn5+fn5+fn5+fn9+f/////7+/v7+/v7+/v7+/v7+/v///v///v39/f39/f7+/v39/f3+/v7+/v7+/v3//v///v////9/fn5+fn5+fn7/f35+f////v7+/v7+/v39/v7+///+//////////////9+f/9/fn5+fn5+fn5////+///+/39+fn5/fn5+fn19fX19fX59fX19fn5+fn9+fn5+fn5+fn5+f//////9/fn////7+/v7+/v7+/f3+/v7///9/fn5+fn5+fn7//39+///+/v7+/v79/f39/f38/Pz8/Pz9/f3+/v7//////////35+fn5+fn59fXx8fH5+fn5+fn5+f/9+fn5+fn7/f35+fn//f35+fn5+fn19fn5+fn5+fn5+f//////+/v7+/v7+/v7+/v79/f39/v7+/////v7//////v7+/v7+/v/+/////3////////7+/v7//////35+fn5+fn5+fn5+fn//////f35+fn7/f35+fn5+fn5///////////////9/fn5+fn5+fn19fX19fn5+fn5+fn5+fn5+fv//////fv/+/v7+/v7+/v7+/////////39+///////+/v7+/v7+/v///v///v///v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7///////9+//////////7+/v7+/v////7///9/fn5+fX19fX18fHx8fHx8fHx9fH19fX5+fn5+fn5+fn5+fn/////+/v7+/v7+/v7+/////35/f////v/+/v7+/v7+/f39/f39/Pz8/Pz7+/v7+/z8/Pz9/f3+/v7+/v7///9/fn5+fn5+fn5+fn5+fn5+fn5+fn5+f////////v//////f35+fn5+fn5+fn5+fn5+fn/////////+/v7+/v7+/v7+/v7+////////f35+fn5+fn//fn////////7+/v7+/v7+/v7+/v7+/v7/f35+fn5+fn19fX59fX5+fn1+fn5+fn////////7+/v39/fz8/f3+/v//f35+fn5+fn5+fX19fX19fX1+fn5+fn///v7///////////7+/v7+/v///39+fn5+fn5+fn5+fX19fX19fX5+fn5+fn///v7+/v39/f38/Pz8/Pz8/Pv8/Pz8/Pz8/f38/f39/v7+/v7+/v7+f/9+/39+fn5+fn//fn//fv9+fn5+fn5+fn59fX19fX59fX5+fX1+fn5+fn9+fn5+fn5+fn5+f/////////////7+/v7+/v7+/v7+/v7+/v7+/v7+/37////////////////+//9/fn//f35+fn19fX19fX19fX1+fn5+fn5//////v7+/v7+/v7+/v7+/v7+/v7+/f39/f39/v3+/v7/f35+fX19fX19fX59fX5+fn5+f//////+//7+/v7+/v79/v7+/v7+/v7+/v9/fn5+fn//fn5+fX5+fn19fX19fX5+fn5+f37/f//+//7+/v39/f38/P38/v7+/n///v7+/f39/Pv6+vv8/P3+/39+fXt7fH3//v79/Pv5+fn9fXd0dHRxcXN4ffv17+7w9vv9/P18dW9vcnn+/P1+f/n19vn7/P98//j1+P59fHx7fHh0cG92fvr49fLw7+/v8fh7cm9vbm5vc3d7+/Pv7vDz9vl/eHNxb25ucnh9/Pv49vX1+Pt/enh3eHh3d3l8f/779/T0';

/// Encodes a single frame's worth of float samples in mu-law
Uint8List encodeFloat32FrameToMuLaw(List<double> floatFrame) {
  final result = Uint8List(floatFrame.length);
  for (int i = 0; i < floatFrame.length; i++) {
    final f = floatFrame[i].clamp(-1.0, 1.0);
    final pcm16 = (f * 32767).toInt();
    final ulawByte = _encodeSample(pcm16);
    result[i] = ulawByte;
  }
  return result;
}

/// Encodes a sample in mu-law
int _encodeSample(int sample) {
  final sign = (sample >> 8) & 0x80;
  if (sign != 0) sample = -sample;
  sample += 0x84; // BIAS
  if (sample > 32635) sample = 32635;

  final exponent = _encodeMuLawTable[(sample >> 7) & 0xFF];
  final mantissa = (sample >> (exponent + 3)) & 0x0F;
  final muLawSample = ~(sign | (exponent << 4) | mantissa) & 0xFF;
  return muLawSample;
}

// dart format off
const _encodeMuLawTable = <int>[
  0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,
  4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
];
// dart format on

// For mu-law -> float or int16
int _decodeMuLawSample(int muLawByte) {
  muLawByte = ~muLawByte & 0xFF;
  final sign = muLawByte & 0x80;
  final exponent = (muLawByte >> 4) & 0x07;
  final mantissa = muLawByte & 0x0F;
  var sample = _decodeTable[exponent] + (mantissa << (exponent + 3));
  if (sign != 0) sample = -sample;
  return sample;
}

// Table needed by decoding
const _decodeTable = <int>[0, 132, 396, 924, 1980, 4092, 8316, 16764];

// Convert a block of mu-law to raw PCM16. For 1 channel, 16k, each sample is 2 bytes.
Uint8List decodeMuLawToPCM16(Uint8List muLawBytes) {
  // For each mu-law byte, produce 2 bytes of PCM16
  final pcm = ByteData(muLawBytes.length * 2);
  for (int i = 0; i < muLawBytes.length; i++) {
    final dec = _decodeMuLawSample(muLawBytes[i]);
    pcm.setInt16(i * 2, dec, Endian.little);
  }
  return pcm.buffer.asUint8List();
}
