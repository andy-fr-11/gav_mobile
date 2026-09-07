import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase/supabase_config.dart';

class SupabaseStorageService {
  static String? buildPublicUrl(String bucket, String path) {
    if (bucket.trim().isEmpty || path.trim().isEmpty) {
      return null;
    }

    final normalizedBucket = bucket.trim();
    final normalizedPath = path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');
    final baseUrl = SupabaseConfig.isConfigured
        ? SupabaseConfig.url
        : 'https://example.supabase.co';
    final origin =
        Uri.tryParse(baseUrl)?.origin ?? 'https://example.supabase.co';

    return '$origin/storage/v1/object/public/$normalizedBucket/$normalizedPath';
  }

  static String? buildPublicUrlOrFallback(
    String bucket,
    String path, {
    String? fallback,
  }) {
    final url = buildPublicUrl(bucket, path);
    return url ?? fallback;
  }

  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    Map<String, String>? metadata,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase n’est pas configuré. Lancez Flutter avec '
        'SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    final normalizedBucket = bucket.trim();
    final normalizedPath = path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');

    if (normalizedBucket.isEmpty || normalizedPath.isEmpty) {
      return null;
    }

    final fileOptions = FileOptions(
      cacheControl: '3600',
      upsert: true,
      contentType: metadata?['content-type'] ?? 'application/octet-stream',
    );

    try {
      await SupabaseConfig.client.storage
          .from(normalizedBucket)
          .uploadBinary(normalizedPath, bytes, fileOptions: fileOptions)
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError('Échec Supabase Storage : $error');
    }

    return buildPublicUrl(normalizedBucket, normalizedPath);
  }

  static Future<String?> replaceFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    Map<String, String>? metadata,
  }) async {
    return uploadFile(
      bucket: bucket,
      path: path,
      bytes: bytes,
      metadata: metadata,
    );
  }

  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }

    final normalizedBucket = bucket.trim();
    final normalizedPath = path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');

    if (normalizedBucket.isEmpty || normalizedPath.isEmpty) {
      return false;
    }

    try {
      await SupabaseConfig.client.storage.from(normalizedBucket).remove([
        normalizedPath,
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> fileExists({
    required String bucket,
    required String path,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }

    final normalizedBucket = bucket.trim();
    final normalizedPath = path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');

    if (normalizedBucket.isEmpty || normalizedPath.isEmpty) {
      return false;
    }

    try {
      final response = await SupabaseConfig.client.storage
          .from(normalizedBucket)
          .list(
            path: normalizedPath.contains('/')
                ? normalizedPath.substring(0, normalizedPath.lastIndexOf('/'))
                : '',
          );

      final fileName = normalizedPath.contains('/')
          ? normalizedPath.substring(normalizedPath.lastIndexOf('/') + 1)
          : normalizedPath;

      return response.any((item) => item.name == fileName);
    } catch (_) {
      return false;
    }
  }

  static Future<String?> uploadProfileImage({
    required String bucket,
    required String userId,
    required Uint8List bytes,
    String fileName = 'profile.png',
  }) async {
    final path = 'users/$userId/$fileName';
    return uploadFile(bucket: bucket, path: path, bytes: bytes);
  }

  static Future<String?> uploadProductImage({
    required String bucket,
    required String productId,
    required Uint8List bytes,
    String fileName = 'product.png',
    String contentType = 'image/png',
  }) async {
    final path = 'products/$productId/$fileName';
    return uploadFile(
      bucket: bucket,
      path: path,
      bytes: bytes,
      metadata: {'content-type': contentType},
    );
  }

  static Future<String?> uploadPrescriptionDocument({
    required String bucket,
    required String patientId,
    required Uint8List bytes,
    String fileName = 'ordonnance.pdf',
  }) async {
    final path = 'prescriptions/$patientId/$fileName';
    return uploadFile(bucket: bucket, path: path, bytes: bytes);
  }
}
