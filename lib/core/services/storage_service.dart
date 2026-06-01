import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../constants/app_colors.dart';
import '../../core/utils/image_compressor.dart';

class StorageService {
  SupabaseClient get _client => supabaseClient;

  Future<List<String>> uploadProductImages(List<File> files) async {
    final urls = <String>[];
    final compressed = await compressImages(files);

    for (final file in compressed) {
      try {
        final ext =
            p.extension(file.path).toLowerCase().replaceAll('.', '').isEmpty
                ? 'jpg'
                : p.extension(file.path).toLowerCase().replaceAll('.', '');
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$ext';

        await _client.storage
            .from(AppStrings.productImagesBucket)
            .upload(fileName, file, fileOptions: FileOptions(upsert: true));

        final publicUrl = _client.storage
            .from(AppStrings.productImagesBucket)
            .getPublicUrl(fileName);

        urls.add(publicUrl);
        debugPrint('[StorageService] Uploaded: $fileName');
      } catch (e) {
        debugPrint('[StorageService] Upload failed: $e');
        await _rollbackUploads(urls);
        rethrow;
      }
    }
    return urls;
  }

  Future<void> deleteImages(List<String> urls) async {
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final bucketIdx = segments.indexOf(AppStrings.productImagesBucket);
        if (bucketIdx >= 0 && bucketIdx + 1 < segments.length) {
          final filePath = segments.sublist(bucketIdx + 1).join('/');
          await _client.storage
              .from(AppStrings.productImagesBucket)
              .remove([filePath]);
        }
      } catch (e) {
        debugPrint('[StorageService] Delete failed for $url: $e');
      }
    }
  }

  Future<void> _rollbackUploads(List<String> uploadedUrls) async {
    debugPrint('[StorageService] Rolling back ${uploadedUrls.length} uploads');
    await deleteImages(uploadedUrls);
  }
}
