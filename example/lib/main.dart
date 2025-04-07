import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manage_install/manage_install.dart';
import 'package:manage_install/types.dart';
import 'package:path_provider/path_provider.dart';

import 'common/utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _defaultUrl = 'https://apps.apple.com/es/app/whatsapp-messenger/id310633997';

  late TextEditingController _textEditingController;
  String _appUrl = '';
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    _textEditingController = TextEditingController(text: _defaultUrl);
    PermissionUtil.requestAll();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Install APK Plugin (Debug)'),
        ),
        body: Container(
          alignment: Alignment.center,
          child: Platform.isAndroid
              ? _buildAndroidContent()
              : Platform.isIOS
              ? _buildIOSPlatform()
              : SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildAndroidContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30, left: 16.0, right: 16),
          child: LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16.0, right: 16, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Text('Downloading ${(_progressValue * 100).toStringAsFixed(0)} %')],
          ),
        ),
        ElevatedButton(
          onPressed: _downloadApk,
          child: Text('Download APK'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _apkDownloadAndInstall,
          child: Text('Download & install APK'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _apkDownloadAndInstall(stdMethod: true),
          child: Text('Download & install APK (std)'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _apkLocalInstall,
          child: Text('Install local APK'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _apkLocalInstall(usePicker: true),
          child: Text('Install local APK (picker)'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _apkLocalInstall(stdMethod: true),
          child: Text('Install local APK (std)'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _apkLocalInstall(stdMethod: true, usePicker: true),
          child: Text('Install local APK (std+picker)'),
        ),
      ],
    );
  }

  Widget _buildIOSPlatform() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        TextField(
          decoration: InputDecoration(hintText: 'URL for app store to launch'),
          controller: _textEditingController,
          onChanged: (String url) => _appUrl = url,
        ),
        ElevatedButton(
          onPressed: _goToAppStore,
          child: Text('Open AppStore'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _goToAppStore(stdMethod: true),
          child: Text('Open AppStore (std)'),
        ),
      ],
    );
  }

  Future<String?> _downloadApk({bool std = true}) async {
    if (std && !_canDownload()) return null;

    _progressValue = 0.0;
    Directory appDocDir = await getTemporaryDirectory();
    String savePath = '${appDocDir.path}/apk_example.apk';
    String fileUrl = 'https://s3.cn-north-1.amazonaws.com.cn/mtab.kezaihui.com/apk/kylinim/zaihui_kylinim_42.apk';
    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      final value = count / total;
      if (_progressValue != value) {
        setState(() {
          if (_progressValue < 1.0) {
            _progressValue = count / total;
          } else {
            _progressValue = 0.0;
          }
        });
      }
    });

    return savePath;
  }

  bool _canDownload({bool showMessage = true}) {
    if (_progressValue != 0 && _progressValue < 1) {
      if (showMessage) _showResultMessage('Wait a moment, downloading...');
      return false;
    }

    return true;
  }

  Future<void> _apkDownloadAndInstall({bool stdMethod = false}) async {
    if (!_canDownload()) return;

    String path = (await _downloadApk())!;

    ManageInstallResult? result;
    if (stdMethod) {
      result = await ManageInstall.installApk(path);
    } else {
      result = await ManageInstall.install(path);
    }

    String message;
    if (result?.isSuccess ?? false) {
      message = 'Installation completed!';
    } else {
      message = 'Installation could not be completed. Error: ${result?.message ?? 'Unknown error'}';
    }

    _showResultMessage(message);
  }

  Future<void> _apkLocalInstall({bool stdMethod = false, bool usePicker = false}) async {
    late String filePath;
    if (usePicker) {
      FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
      filePath = filePickerResult?.files.single.path ?? '';
      if (filePath.isEmpty) {
        _showResultMessage('To start the installation, select the APK file into the file explorer.');
      }

    } else {
      Directory appDocDir = await getTemporaryDirectory();
      filePath = '${appDocDir.path}/apk_example.apk';
    }

    ManageInstallResult? result;
    if (stdMethod) {
      result = await ManageInstall.installApk(filePath);
    } else {
      result = await ManageInstall.install(filePath);
    }

    String message;
    if (result?.isSuccess ?? false) {
      message = 'Installation completed!';
    } else {
      message = 'Installation could not be completed. Error: ${result?.message ?? 'Unknown error'}';
    }

    _showResultMessage(message);
  }

  Future<void> _goToAppStore({bool stdMethod = false}) async {
    ManageInstallResult? result;
    if (stdMethod) {
      result = await ManageInstall.goToAppStore(_appUrl.isNotEmpty ? _appUrl : _defaultUrl);
    } else {
      result = await ManageInstall.install(_appUrl.isNotEmpty ? _appUrl : _defaultUrl);
    }

    String message;
    if (result?.isSuccess ?? false) {
      message = 'AppStore opened successfully!';
    } else {
      message = 'AppStore could not be opened. Error: ${result?.message ?? 'Unknown error'}';
    }

    _showResultMessage(message);
  }

  void _showResultMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (kDebugMode) {
      print(message);
    }
  }
}
