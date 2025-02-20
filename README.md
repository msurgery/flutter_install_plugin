[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/youxiachai/flutter_install_plugin/blob/master/LICENSE)

A flutter plugin for install apk for android and open appStore on iOS.\
Updated to Flutter v3.27.4.

Original plugin `InstallPlugin` by `hui-z`. Original repository: https://github.com/hui-z/flutter_install_plugin

# manage_install

We use the `manage_install` plugin to install apk for android; and using url to go to app store for iOS.

## Usage

To use this plugin, add `manage_install` as a dependency in your pubspec.yaml file. For example:
```yaml
dependencies:
  manage_install: '^2.1.2'
```

## iOS
Your project need create with swift.

##  Android
You need to request permission for `READ_EXTERNAL_STORAGE` to read the APK file. 
You can handle the storage permission using [flutter_permission_handler](https://github.com/BaseflowIT/flutter-permission-handler).
```
    <!-- read permissions for external storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

In `Android version >= 8.0`, You need to request permission for `REQUEST_INSTALL_PACKAGES` 
to install the APK file.
```
    <!-- installation package permissions -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

In `Android version <= 6.0`, You need to request permission for `WRITE_EXTERNAL_STORAGE` to copy 
the APK from the app private location to the download directory.
```
    <!-- write permissions for external storage -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Example
Install APK after download it from the internet. **Only on Android.**

``` dart
    Future<String?> _downloadApk() async {
        Directory appDocDir = await getTemporaryDirectory();
        String savePath = '${appDocDir.path}/example.apk';
        String fileUrl = 'https://fake-apk/file.apk';
        await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) { ... });
    
        return savePath;
    }

    Future<void> _apkDownloadAndInstall() async {
        String path = (await _downloadApk())!;

        ManageInstallResult? result;
        result = await ManageInstall.installApk(path);
        // result = await ManageInstall.install(path);

        String message = (result?.isSuccess ?? false)
            ? 'Installation completed!'
            : 'Installation could not be completed. Error: ${result?.message ?? 'Unknown error'}';

        (...)
    }
```

Install APK directly from the local storage. **Only on Android.**
``` dart
    Future<void> _apkLocalInstall({bool usePicker = false}) async {
        late String filePath;
        if (usePicker) {
            FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
            filePath = filePickerResult?.files.single.path ?? '';
            if (filePath.isEmpty) {
                _showResultMessage('To start the installation, select the APK file into the file explorer.');
            }

        } else {
          Directory appDocDir = await getTemporaryDirectory();
          filePath = '${appDocDir.path}/example.apk';
        }

        ManageInstallResult? result = await ManageInstall.installApk(filePath);
        // ManageInstallResult? result = await ManageInstall.install(filePath);

        String message = (result?.isSuccess ?? false)
            ? 'Installation completed!'
            : 'Installation could not be completed. Error: ${result?.message ?? 'Unknown error'}';

        (...)
  }
```

Go to AppStore for update or download an app. **Only available for iOS.**
``` dart
    Future<void> _goToAppStore(String storeUri) async {
        ManageInstallResult? result = await ManageInstall.goToAppStore(storeUri);
        ManageInstallResult? result = await ManageInstall.install(storeUri);
    
        String message = (result?.isSuccess ?? false) 
            ? 'AppStore opened successfully!';
            : 'AppStore could not be opened. Error: ${result?.message ?? 'Unknown error'}';
    
        (...)
    }
```
