import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:manage_install/manage_install_platform_interface.dart';

import 'types.dart';

/// An implementation of [ManageInstallPlatform] that uses method channels.
class MethodChannelManageInstall extends ManageInstallPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('manage_install');

  /// Installs an APK file on Android devices
  ///
  /// [filePath] - Absolute path to the APK file
  /// [appId] - Optional application ID, required for Android 24+ (Nougat)
  ///
  /// Returns an [ManageInstallResult] indicating success or failure
  @override
  Future<ManageInstallResult?> installApk(String filePath, {String appId = ''}) async {
    Map<String, String> params = {'filePath': filePath, 'appId': appId};
    final result = await methodChannel.invokeMethod<dynamic>('installApk', params);
    return ManageInstallResult.fromJson(Map<String, dynamic>.from(result!));
  }

  /// Redirects to the App Store on iOS devices
  ///
  /// [storeUri] - App Store URL for the application
  ///
  /// Returns an [ManageInstallResult] indicating success or failure
  @override
  Future<ManageInstallResult?> goToAppStore(String storeUri) async {
    if (Platform.isAndroid) {
      return ManageInstallResult(
        isSuccess: false,
        message: 'Cannot open PlayStore on Android devices',
      );
    }

    Map<String, String> params = {'storeUri': storeUri};
    final result = await methodChannel.invokeMethod<dynamic>('goToAppStore', params);
    return ManageInstallResult.fromJson(Map<String, dynamic>.from(result!));
  }
}
