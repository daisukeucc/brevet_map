import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.example.brevet_map/gpx"
  private var gpxChannel: FlutterMethodChannel?
  private var pendingGpxContent: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // コールドスタートで GPX ファイルをタップして起動した場合、URL が launchOptions で渡される
    if let url = launchOptions?[.url] as? URL, isGpxUrl(url) {
      if let content = try? String(contentsOf: url, encoding: .utf8) {
        pendingGpxContent = content
      }
    }

    let controller = window?.rootViewController as! FlutterViewController
    gpxChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )
    gpxChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialGpxContent" {
        if let content = self?.pendingGpxContent {
          self?.pendingGpxContent = nil
          result(content)
        } else {
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? ""
    GMSServices.provideAPIKey(apiKey)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard isGpxUrl(url), let content = try? String(contentsOf: url, encoding: .utf8) else {
      return false
    }
    pendingGpxContent = content
    if gpxChannel != nil {
      gpxChannel?.invokeMethod("onGpxFileReceived", arguments: content)
    }
    return true
  }

  private func isGpxUrl(_ url: URL) -> Bool {
    url.pathExtension.lowercased() == "gpx" || url.absoluteString.lowercased().contains("gpx")
  }
}
