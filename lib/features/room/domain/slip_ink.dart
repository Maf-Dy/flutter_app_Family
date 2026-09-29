import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A name written by finger instead of typed: a small PNG of the scribble,
/// dark ink on a clear background, so it can be tinted to sit on any slip.
///
/// Only built through [tryParse], which checks it really is a PNG within the
/// size limits, so a friend's browser can't slip anything else into the bowl.
@immutable
final class SlipInk {
  const SlipInk._(this.png, this.width, this.height);

  /// The biggest drawing kept; pads draw at this size, or crop it smaller.
  static const maxWidth = 480;
  static const maxHeight = 240;

  /// A thick-ink line drawing this size is a few KB; anything near this is not a drawing.
  static const maxBytes = 80 * 1024;

  /// The text a hand-drawn slip carries, for places that can only show text (share cards).
  static const marker = '✍️';

  static const _dataUrlPrefix = 'data:image/png;base64,';
  static const _signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  final Uint8List png;
  final int width;
  final int height;

  /// The drawing, or null when [bytes] are not a PNG within [maxWidth] x [maxHeight] and [maxBytes].
  static SlipInk? tryParse(List<int> bytes) {
    if (bytes.length > maxBytes || bytes.length < 33) return null;
    for (var i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) return null;
    }
    // The first chunk must be the 13-byte header: width and height come first, big-endian.
    final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(8, 33)));
    if (data.getUint32(0) != 13 || String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') return null;
    final width = data.getUint32(8);
    final height = data.getUint32(12);
    if (width == 0 || height == 0 || width > maxWidth || height > maxHeight) return null;
    return SlipInk._(Uint8List.fromList(bytes), width, height);
  }

  /// Reads the `data:image/png;base64,…` URL a browser's canvas gives. Null when it isn't a valid drawing.
  static SlipInk? fromDataUrl(String url) {
    if (!url.startsWith(_dataUrlPrefix)) return null;
    // Base64 of maxBytes, with room for padding.
    if (url.length - _dataUrlPrefix.length > (maxBytes * 4 ~/ 3) + 4) return null;
    try {
      return tryParse(base64.decode(url.substring(_dataUrlPrefix.length)));
    } on FormatException {
      return null;
    }
  }

  String toDataUrl() => '$_dataUrlPrefix${base64.encode(png)}';

  /// A short fingerprint of the drawing, e.g. for an HTTP ETag.
  String get tag {
    // FNV-1a: plenty to tell drawings apart, no packages needed.
    var hash = 0x811c9dc5;
    for (final b in png) {
      hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return '${hash.toRadixString(16)}-${png.length}';
  }

  @override
  bool operator ==(Object other) => other is SlipInk && listEquals(other.png, png);

  @override
  int get hashCode => Object.hash(tag, width, height);
}
