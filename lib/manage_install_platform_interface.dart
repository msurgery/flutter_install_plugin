import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'manage_install_method_channel.dart';
import 'types.dart';

abstract class ManageInstallPlatformInterface extends PlatformInterface {
  /// Constructs a ManageInstallPlatformInterface.
  ManageInstallPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static ManageInstallPlatformInterface _instance = MethodChannelManageInstall();

  /// The default instance of [ManageInstallPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelManageInstall].
  static ManageInstallPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ManageInstallPlatform] when
  /// they register themselves.
  static set instance(ManageInstallPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<ManageInstallResult?> installApk(String filePath, {String appId = ''}) {
    throw UnimplementedError('installApk() has not been implemented.');
  }

  Future<ManageInstallResult?> goToAppStore(String storeUri) {
    throw UnimplementedError('goToAppStore() has not been implemented.');
  }
}
