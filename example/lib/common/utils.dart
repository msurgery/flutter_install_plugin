import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dialog.dart';

/// Utility class for handling permissions
class PermissionUtil {
  /// Android permissions list
  static List<Permission> androidPermissions = <Permission>[
    // Add required permissions here
    Permission.storage,
    Permission.requestInstallPackages,
  ];

  /// iOS permissions list
  static List<Permission> iosPermissions = <Permission>[
    // Add required permissions here
    // Permission.storage
  ];

  /// Request all platform-specific permissions
  ///
  /// Returns a [Map\<Permission, PermissionStatus\>] of permissions and their status
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    if (Platform.isIOS) {
      return await iosPermissions.request();
    }

    return await androidPermissions.request();
  }

  /// Request a specific permission
  ///
  /// [permission] The permission to request
  ///
  /// Returns a [Map\<Permission, PermissionStatus\>] with the permission and its status
  static Future<Map<Permission, PermissionStatus>> request(Permission permission) async {
    final List<Permission> permissions = <Permission>[permission];
    return await permissions.request();
  }

  /// Check if any permission in the result map is denied
  ///
  /// [result] Map of permissions and their status
  ///
  /// Returns [bool] with a true value if any permission is denied
  static bool isDenied(Map<Permission, PermissionStatus> result) {
    var isDenied = false;
    result.forEach((key, value) {
      if (value == PermissionStatus.denied) {
        isDenied = true;
        return;
      }
    });

    return isDenied;
  }

  /// Shows a dialog when permissions are denied
  ///
  /// [context] The build context
  ///
  /// Shows a dialog prompting the user to enable permissions in app settings
  static void showDeniedDialog(BuildContext context) {
    HDialog.show(
      context: context,
      title: 'Permission Request Error',
      content:
      'Please enable all required permissions in [App Info] - [Permission Management] to use the app\'s features normally',
      options: <DialogAction>[DialogAction(text: 'Go to Settings', onPressed: openAppSettings)],
    );
  }

  /// Check if a specific permission is granted
  ///
  /// [permission] The permission to check

  /// Returns [bool]. True value if the permission is granted, false otherwise
  static Future<bool> checkGranted(Permission permission) async {
    PermissionStatus storageStatus = await permission.status;
    return storageStatus == PermissionStatus.granted;
  }
}
