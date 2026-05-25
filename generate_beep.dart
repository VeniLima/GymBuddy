import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final sampleRate = 44100;
  final duration = 0.4; // 0.4 segundos de beep
  final numSamples = (sampleRate * duration).toInt();
  final dataSize = numSamples * 2;
  final bytes = BytesBuilder();

  // WAV Header
  bytes.add('RIFF'.codeUnits);
  final fileSize = 36 + dataSize;
  bytes.add([fileSize & 0xff, (fileSize >> 8) & 0xff, (fileSize >> 16) & 0xff, (fileSize >> 24) & 0xff]);
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  bytes.add([16, 0, 0, 0]); // PCM Format
  bytes.add([1, 0]); // Audio format 1
  bytes.add([1, 0]); // Num channels 1
  bytes.add([sampleRate & 0xff, (sampleRate >> 8) & 0xff, (sampleRate >> 16) & 0xff, (sampleRate >> 24) & 0xff]); // Sample rate
  final byteRate = sampleRate * 2;
  bytes.add([byteRate & 0xff, (byteRate >> 8) & 0xff, (byteRate >> 16) & 0xff, (byteRate >> 24) & 0xff]); // Byte rate
  bytes.add([2, 0]); // Block align
  bytes.add([16, 0]); // Bits per sample
  bytes.add('data'.codeUnits);
  bytes.add([dataSize & 0xff, (dataSize >> 8) & 0xff, (dataSize >> 16) & 0xff, (dataSize >> 24) & 0xff]); // Data size

  // Frequência do Beep: 800 Hz (frequência clássica de despertador)
  final freq = 800.0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final value = (sin(2 * pi * freq * t) * 32767).toInt();
    bytes.add([value & 0xff, (value >> 8) & 0xff]);
  }

  File('assets/beep.wav').createSync(recursive: true);
  File('assets/beep.wav').writeAsBytesSync(bytes.toBytes());
  print('Generated beep.wav');
}
