import UIKit
import Flutter
import GoogleMaps

private let kShareSchemePrefix = "ShareMedia-com.example.brevetMap"
private let kAppGroupId = "group.com.example.brevetMap"
private let kSharedUrlKey = "shared_url"

@main
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
    // Google Maps は最初に初期化する必要がある（地図表示前に呼ばれること）
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? ""
    GMSServices.provideAPIKey(apiKey)

    // コールドスタートで GPX ファイルをタップして起動した場合、URL が launchOptions で渡される
    if let url = launchOptions?[.url] as? URL {
      if isShareScheme(url) {
        loadSharedUrlFromAppGroup()
      } else if isGpxUrl(url), let content = try? String(contentsOf: url, encoding: .utf8) {
        pendingGpxContent = content
      }
    }

    // プラグイン登録を先に実行し、メソッドチャネルは super 実行後
    // （FlutterEngine の binaryMessenger 準備完了後）に設定
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      setupMethodChannels(controller: controller)
    }

    return result
  }

  private func setupMethodChannels(controller: FlutterViewController) {
    let messenger = controller.binaryMessenger
    gpxChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
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
      binaryMessenger: messenger
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
