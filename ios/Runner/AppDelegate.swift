import UIKit
import Flutter
import GoogleMaps

private let kShareSchemePrefix = "ShareMedia-com.example.brevetMap"
private let kAppGroupId = "group.com.example.brevetMap"
private let kSharedUrlKey = "shared_url"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.example.brevet_map/gpx"
  private let shareChannelName = "com.example.brevet_map/share"
  private var gpxChannel: FlutterMethodChannel?
  private var shareChannel: FlutterMethodChannel?
  private var pendingGpxContent: String?
  private var pendingSharedUrl: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // コールドスタートで GPX ファイルをタップして起動した場合、URL が launchOptions で渡される
    if let url = launchOptions?[.url] as? URL {
      if isShareScheme(url) {
        loadSharedUrlFromAppGroup()
      } else if isGpxUrl(url), let content = try? String(contentsOf: url, encoding: .utf8) {
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

    shareChannel = FlutterMethodChannel(
      name: shareChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    shareChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialSharedUrl" {
        if self?.pendingSharedUrl == nil {
          self?.loadSharedUrlFromAppGroup()
        }
        if let url = self?.pendingSharedUrl {
          self?.pendingSharedUrl = nil
          result(url)
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
    if isShareScheme(url) {
      loadSharedUrlFromAppGroup()
      if let sharedUrl = pendingSharedUrl {
        shareChannel?.invokeMethod("onSharedUrlReceived", arguments: sharedUrl)
        pendingSharedUrl = nil
      }
      return true
    }
    if isGpxUrl(url), let content = try? String(contentsOf: url, encoding: .utf8) {
      pendingGpxContent = content
      if gpxChannel != nil {
        gpxChannel?.invokeMethod("onGpxFileReceived", arguments: content)
      }
      return true
    }
    return false
  }

  private func isShareScheme(_ url: URL) -> Bool {
    url.absoluteString.hasPrefix(kShareSchemePrefix)
  }

  private func isGpxUrl(_ url: URL) -> Bool {
    url.pathExtension.lowercased() == "gpx" || url.absoluteString.lowercased().contains("gpx")
  }

  private func loadSharedUrlFromAppGroup() {
    if let userDefaults = UserDefaults(suiteName: kAppGroupId),
       let url = userDefaults.string(forKey: kSharedUrlKey) {
      userDefaults.removeObject(forKey: kSharedUrlKey)
      userDefaults.synchronize()
      pendingSharedUrl = url
    }
  }
}
