import UIKit
import Flutter

private let kShareSchemePrefix = "ShareMedia-com.brevetmap"
private let kAppGroupId = "group.com.brevetmap"
private let kSharedUrlKey = "shared_url"
private let kPendingGpxContentKey = "pending_gpx_content"
private let kPendingGpxBasenameKey = "pending_gpx_basename"

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.brevetmap/gpx"
  private let shareChannelName = "com.brevetmap/share"
  private var gpxChannel: FlutterMethodChannel?
  private var shareChannel: FlutterMethodChannel?
  private var pendingGpxContent: String?
  /// 拡張子 `.gpx` を除いたファイル名（インポート表示・エクスポート既定名用）
  private var pendingGpxBasename: String?
  private var pendingSharedUrl: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // コールドスタートで GPX ファイルをタップして起動した場合、URL が launchOptions で渡される
    if let url = launchOptions?[.url] as? URL {
      if isShareScheme(url) {
        if url.absoluteString.hasSuffix(":gpx") {
          loadPendingGpxFromAppGroup()
        } else {
          loadSharedUrlFromAppGroup()
        }
      } else if isGpxUrl(url) {
        pendingGpxContent = readGpxContent(from: url)
        pendingGpxBasename = url.deletingPathExtension().lastPathComponent
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
          let base = self?.pendingGpxBasename
          self?.pendingGpxContent = nil
          self?.pendingGpxBasename = nil
          if let b = base, !b.isEmpty {
            result(["content": content, "basename": b])
          } else {
            result(["content": content])
          }
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
      if url.absoluteString.hasSuffix(":gpx") {
        loadPendingGpxFromAppGroup()
        if let content = pendingGpxContent {
          let base = pendingGpxBasename
          pendingGpxContent = nil
          pendingGpxBasename = nil
          if gpxChannel != nil {
            var args: [String: Any] = ["content": content]
            if let b = base, !b.isEmpty { args["basename"] = b }
            gpxChannel?.invokeMethod("onGpxFileReceived", arguments: args)
          } else {
            pendingGpxContent = content
            pendingGpxBasename = base
          }
        }
      } else {
        loadSharedUrlFromAppGroup()
        if let sharedUrl = pendingSharedUrl {
          shareChannel?.invokeMethod("onSharedUrlReceived", arguments: sharedUrl)
          pendingSharedUrl = nil
        }
      }
      return true
    }
    if isGpxUrl(url), let content = readGpxContent(from: url) {
      let base = url.deletingPathExtension().lastPathComponent
      if gpxChannel != nil {
        gpxChannel?.invokeMethod("onGpxFileReceived", arguments: [
          "content": content,
          "basename": base,
        ])
      } else {
        pendingGpxContent = content
        pendingGpxBasename = base
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

  /// 他アプリから共有された GPX ファイルを読み取る。セキュリティスコープ付きリソースに対応。
  private func readGpxContent(from url: URL) -> String? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
    return try? String(contentsOf: url, encoding: .utf8)
  }

  private func loadSharedUrlFromAppGroup() {
    if let userDefaults = UserDefaults(suiteName: kAppGroupId),
       let url = userDefaults.string(forKey: kSharedUrlKey) {
      userDefaults.removeObject(forKey: kSharedUrlKey)
      userDefaults.synchronize()
      pendingSharedUrl = url
    }
  }

  private func loadPendingGpxFromAppGroup() {
    guard let userDefaults = UserDefaults(suiteName: kAppGroupId),
          let content = userDefaults.string(forKey: kPendingGpxContentKey) else { return }
    let base = userDefaults.string(forKey: kPendingGpxBasenameKey)
    userDefaults.removeObject(forKey: kPendingGpxContentKey)
    userDefaults.removeObject(forKey: kPendingGpxBasenameKey)
    userDefaults.synchronize()
    pendingGpxContent = content
    if let b = base, !b.isEmpty {
      pendingGpxBasename = b
    } else {
      pendingGpxBasename = nil
    }
  }
}
