import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../config/app_config.dart';
import '../utils/logger_utils.dart';
import 'supabase_auth_bridge.dart';

/// Uploads images to the SafarShare Supabase storage buckets via direct
/// HTTP, using the JWT cached in [SupabaseAuthBridge] as the Bearer
/// token. We skip the Supabase Flutter SDK's storage client because the
/// SDK's auth state is tied to its own session manager and we mint our
/// own JWTs out-of-band via the firebase-bridge function.
class SupabaseStorageService {
  static const String _tag = 'StorageService';
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB
  static const String profileBucket = 'profile_photos';
  static const String vehicleBucket = 'vehicle_photos';

  static const Set<String> _allowedMime = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  };

  /// Uploads to `<userId>/avatar.<ext>` in [profileBucket] and returns
  /// the public URL.
  Future<String> uploadProfilePhoto({
    required File file,
    required String userId,
  }) {
    return _upload(
      bucket: profileBucket,
      path: '$userId/avatar${_extFor(file)}',
      file: file,
    );
  }

  /// Uploads to `<userId>/<vehicleId>.<ext>` in [vehicleBucket].
  Future<String> uploadVehiclePhoto({
    required File file,
    required String userId,
    required String vehicleId,
  }) {
    return _upload(
      bucket: vehicleBucket,
      path: '$userId/$vehicleId${_extFor(file)}',
      file: file,
    );
  }

  Future<String> _upload({
    required String bucket,
    required String path,
    required File file,
  }) async {
    Log.i(_tag, 'upload → $bucket/$path');
    final size = await file.length();
    if (size > maxFileBytes) {
      Log.w(_tag, 'Rejected: file too large ($size bytes)');
      throw StorageUploadException(
        'File is ${(size / 1024 / 1024).toStringAsFixed(1)} MB; '
        'the bucket cap is 5 MB.',
      );
    }
    final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
    if (!_allowedMime.contains(mime)) {
      Log.w(_tag, 'Rejected: unsupported mime $mime');
      throw StorageUploadException(
        'Unsupported image type: $mime. Allowed: jpeg/png/webp/heic.',
      );
    }

    final bridge = SupabaseAuthBridge.instance;
    final token = bridge.accessToken ??
        await bridge.refreshIfNeeded().then((_) => bridge.accessToken);
    if (token == null) {
      Log.e(_tag, 'No bridge token — refusing to upload.');
      throw const StorageUploadException(
        'Not signed in to Supabase. Sign in via Firebase OTP first.',
      );
    }

    final uploadUri = Uri.parse(
      '${AppConfig.supabaseUrl}/storage/v1/object/$bucket/$path',
    );
    final bytes = await file.readAsBytes();
    final resp = await http.post(
      uploadUri,
      headers: {
        // The Supabase API gateway expects an apikey on storage requests,
        // same as the PostgREST calls; the Bearer JWT then drives the
        // owner-only storage RLS. Without apikey the gateway rejects it.
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer $token',
        'Content-Type': mime,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      Log.e(_tag, 'Upload failed (${resp.statusCode}): ${resp.body}');
      throw StorageUploadException(
        'Upload failed (${resp.statusCode}): ${resp.body}',
      );
    }

    // Cache-buster so the UI re-fetches after upsert.
    final publicUrl =
        '${AppConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';
    final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    Log.i(_tag, 'upload OK → $url');
    return url;
  }

  String _extFor(File file) {
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.heic')) return '.heic';
    return '.jpg';
  }
}

class StorageUploadException implements Exception {
  final String message;
  const StorageUploadException(this.message);
  @override
  String toString() => message;
}
