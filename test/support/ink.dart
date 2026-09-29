import 'dart:convert';
import 'dart:typed_data';

import 'package:family_game/features/room/domain/slip_ink.dart';

/// A real 1x1 PNG, small enough to decode anywhere.
final tinyPng = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// A PNG signature and header claiming [width] x [height], then [extra] bytes:
/// enough for [SlipInk]'s checks, not to draw. [tag] makes drawings differ.
Uint8List pngHeader(int width, int height, {int extra = 12, int tag = 0}) {
  final header = ByteData(8 + 25 + extra);
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (final (i, b) in signature.indexed) {
    header.setUint8(i, b);
  }
  header
    ..setUint32(8, 13)
    ..setUint8(12, 0x49)
    ..setUint8(13, 0x48)
    ..setUint8(14, 0x44)
    ..setUint8(15, 0x52)
    ..setUint32(16, width)
    ..setUint32(20, height)
    ..setUint8(24, 8)
    ..setUint8(25, 6);
  if (extra > 0) header.setUint8(33, tag % 256);
  return header.buffer.asUint8List();
}

/// A drawing for tests; different [tag]s give different drawings.
SlipInk testInk([int tag = 0]) => SlipInk.tryParse(pngHeader(40, 20, tag: tag))!;
