import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

Future<File> compressImage(File file,
    {int maxWidth = 1200, int quality = 80}) async {
  final dir = file.parent.path;
  final targetPath = p.join(dir, 'compressed_${p.basename(file.path)}');

  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: quality,
    minWidth: maxWidth,
    minHeight: maxWidth,
    format: CompressFormat.jpeg,
    keepExif: false,
  );

  if (result == null) {
    debugPrint('[ImageCompressor] Compression failed, returning original');
    return file;
  }

  final compressed = File(result.path);
  final originalSize = await file.length();
  final compressedSize = await compressed.length();
  debugPrint(
      '[ImageCompressor] ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB '
      '(${(100 - (compressedSize / originalSize * 100)).round()}% reduction)');

  return compressed;
}

Future<List<File>> compressImages(List<File> files,
    {int maxWidth = 1200, int quality = 80}) async {
  final results = <File>[];
  for (final file in files) {
    try {
      results
          .add(await compressImage(file, maxWidth: maxWidth, quality: quality));
    } catch (e) {
      debugPrint('[ImageCompressor] Error compressing ${file.path}: $e');
      results.add(file);
    }
  }
  return results;
}
