import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  PermissionHelper._();

  /// Requests all necessary permissions for the app upfront after splash.
  /// Handles camera, photos/media storage, and push notifications.
  static Future<void> requestAppPermissions() async {
    try {
      final permissionsToRequest = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.storage,
        Permission.notification,
      ];

      final statuses = await permissionsToRequest.request();
      debugPrint('[PermissionHelper] Requested permissions status: $statuses');
    } catch (e) {
      debugPrint('[PermissionHelper] Error requesting permissions: $e');
    }
  }
}
