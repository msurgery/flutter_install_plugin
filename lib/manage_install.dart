import 'dart:io';

import 'manage_install_platform_interface.dart';
import 'types.dart';

/// Handles APK installation on Android and App Store redirection on iOS
class ManageInstall {
  /// Installs an APK on Android or redirects to App Store on iOS
  ///
  /// [packagePath] - On Android: absolute file path to the APK
  ///                 On iOS: App Store URL
  /// [appId] - Optional application ID for Android. Defaults to empty string if not provided, cause the
  /// caller used the 'applicationId' which is defined into the build.gradle file.
  ///
  /// Returns an [ManageInstallResult] indicating success or failure
  static Future<ManageInstallResult?> install(String packagePath, {String appId = ''}) async {
    if (Platform.isAndroid) {
      return ManageInstallPlatformInterface.instance.installApk(packagePath, appId: appId);
    } else if (Platform.isIOS) {
      return ManageInstallPlatformInterface.instance.goToAppStore(packagePath);
    }

    return ManageInstallResult(isSuccess: false, message: 'Unsupported device');
  }

  /// Installs an APK on Android
  ///
  /// [filePath] - absolute file path to the APK
  /// [appId] - Optional application ID for Android. Defaults to empty string if not provided, cause the
  /// caller used the 'applicationId' which is defined into the build.gradle file.
  ///
  /// Returns an [ManageInstallResult] indicating success or failure
  static Future<ManageInstallResult?> installApk(String filePath, {String appId = ''}) async {
    if (!Platform.isAndroid) {
      return ManageInstallResult(isSuccess: false, message: 'Unsupported device');
    }

    return ManageInstallPlatformInterface.instance.installApk(filePath, appId: appId);
  }

  /// Redirects to App Store on iOS
  ///
  /// [storeUri] - On iOS: App Store URL
  ///
  /// Returns an [ManageInstallResult] indicating success or failure
  static Future<ManageInstallResult?> goToAppStore(String storeUri) async {
    if (Platform.isIOS) {
      return ManageInstallResult(isSuccess: false, message: 'Unsupported device');
    }

    return ManageInstallPlatformInterface.instance.goToAppStore(storeUri);
  }
}
