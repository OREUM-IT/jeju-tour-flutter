import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'models.dart';

/// Reads original metadata before resizing; never fabricates location or time.
Json prepareEvidence(Uint8List bytes) {
  if (bytes.length > 15 * 1024 * 1024) {
    throw const FormatException('15MB 이하의 사진을 선택해 주세요.');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('JPEG·PNG 사진을 선택해 주세요.');
  final exif = <String, dynamic>{};
  final date = decoded.exif.exifIfd[0x9003]?.toString();
  if (date != null && date.isNotEmpty) exif['dateTime'] = date;
  final gps = decoded.exif.gpsIfd;
  double? angle(int tag) {
    final value = gps[tag];
    if (value == null || value.length < 3) return null;
    return value.toDouble(0) +
        value.toDouble(1) / 60 +
        value.toDouble(2) / 3600;
  }

  final lat = angle(2), lon = angle(4);
  if (lat != null && lon != null) {
    exif['lat'] = lat * (gps[1]?.toString().contains('S') == true ? -1 : 1);
    exif['lon'] = lon * (gps[3]?.toString().contains('W') == true ? -1 : 1);
  }
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1200 || oriented.height > 1200
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1200 : null,
          height: oriented.height > oriented.width ? 1200 : null,
        )
      : oriented;
  final jpeg = img.encodeJpg(resized, quality: 80);
  return {
    'photo': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
    'exif': exif.isEmpty ? null : exif,
    'preview': jpeg,
  };
}
