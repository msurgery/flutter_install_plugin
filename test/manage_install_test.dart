import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_install/manage_install.dart';
import 'package:manage_install/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('manage_install');
  final List<MethodCall> log = <MethodCall>[];
  String? response;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
        (MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    },
  );

  tearDown(() {
    log.clear();
  });

  test('install test', () async {
    response = 'Success';
    final fakePath = 'fake.apk';
    final fakeAppId = 'com.example.install';
    final ManageInstallResult? result = await ManageInstall.install(fakePath, appId: fakeAppId);
    expect(
      log,
      <Matcher>[
        isMethodCall('install', arguments: {'filePathOrStoreUri': fakePath, 'appId': fakeAppId})
      ],
    );
    expect(result, response);
  });

  test('install test', () async {
    response = 'Success';
    final fakeUrl = 'fake_url';
    final ManageInstallResult? result = await ManageInstall.install(fakeUrl);
    expect(
      log,
      <Matcher>[
        isMethodCall('install', arguments: {'filePathOrStoreUri': fakeUrl})
      ],
    );
    expect(result, response);
  });

  test('installApk test', () async {
    response = 'Success';
    final fakePath = 'fake.apk';
    final fakeAppId = 'com.example.install';
    final ManageInstallResult? result = await ManageInstall.installApk(fakePath, appId: fakeAppId);
    expect(
      log,
      <Matcher>[
        isMethodCall('installApk', arguments: {'filePath': fakePath, 'appId': fakeAppId})
      ],
    );
    expect(result, response);
  });

  test('goToAppStore test', () async {
    response = null;
    final fakeUrl = 'fake_url';
    final ManageInstallResult? result = await ManageInstall.goToAppStore(fakeUrl);
    expect(
      log,
      <Matcher>[
        isMethodCall('goToAppStore', arguments: {'storeUri': fakeUrl})
      ],
    );
    expect(result, isNull);
  });
}
