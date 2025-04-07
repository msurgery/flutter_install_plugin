import Flutter
import UIKit

public class ManageInstallPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "manage_install", binaryMessenger: registrar.messenger())
    let instance = ManageInstallPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "goToAppStore":
      print(call.arguments ?? "null")
      guard let storeUri = (call.arguments as? Dictionary<String, Any>)?["storeUri"] as? String else {
        var _result = SaveResultModel(
          isSuccess: false, 
          message: "[ManageInstall] 'goToAppStore' called with empty argument 'storeUri'."
        )
        result(_result.toDict())
        return
      }

      goToAppStore(storeUri: storeUri, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Jump to the app's AppStore page
  func goToAppStore(storeUri: String, result: @escaping FlutterResult) {
    if let url = URL(string: storeUri) {
      if UIApplication.shared.canOpenURL(url) {
        // According to the iOS system version, handle them separately
        if #available(iOS 10, *) {
          UIApplication.shared.open(url, options: [:],completionHandler: {(success) in })
        } else {
          UIApplication.shared.openURL(url)
        }

        var _result = SaveResultModel(isSuccess: false, message: nil)
        result(_result.toDict())

      } else {
        var _result = SaveResultModel(
          isSuccess: false, 
          message: "[ManageInstall] The used 'storeUri' could not be opened into AppStore."
        )

        result(_result.toDict())
      }
    }
  }
}

public struct SaveResultModel: Encodable {
  var isSuccess: Bool!
  var message: String?

  func toDict() -> [String:Any]? {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(self) else { return nil }
    if (!JSONSerialization.isValidJSONObject(data)) {
      return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
    }

    return nil
  }
}