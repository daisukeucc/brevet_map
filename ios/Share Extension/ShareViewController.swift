//
//  ShareViewController.swift
//  Share Extension
//
//  MethodChannel ベースの共有URL受信。receive_sharing_intent に依存しない独自実装。
//

import UIKit
import Social
import MobileCoreServices

private let kAppGroupId = "group.com.example.brevetMap"
private let kSharedUrlKey = "shared_url"
private let kPendingGpxContentKey = "pending_gpx_content"
private let kShareSchemePrefix = "ShareMedia-com.example.brevetMap"

private let kUTTypeURL = "public.url"
private let kUTTypePlainText = "public.plain-text"
private let kUTTypeFileURL = "public.file-url"
private let kUTTypeData = "public.data"
private let kUTTypeGPX = "com.topografix.gpx"

class ShareViewController: SLComposeServiceViewController {

    private var sharedUrl: String?

    override func isContentValid() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Send"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extractSharedContent()
    }

    override func didSelectPost() {
        saveAndRedirect()
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeURL, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let url = data as? URL {
                                self?.sharedUrl = url.absoluteString
                            }
                        }
                    }
                    return
                }
                if attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText) {
                    attachment.loadItem(forTypeIdentifier: kUTTypePlainText, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let text = data as? String, !text.isEmpty {
                                self?.sharedUrl = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                    }
                    return
                }
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeFileURL) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeFileURL, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let url = data as? URL, self?.isGpxUrl(url) == true {
                                self?.loadAndSaveGpx(from: url)
                            }
                        }
                    }
                    return
                }
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeGPX) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeGPX, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let url = data as? URL {
                                self?.loadAndSaveGpx(from: url)
                            } else if let fileData = data as? Data, let text = String(data: fileData, encoding: .utf8) {
                                self?.saveGpxContentAndOpenApp(content: text)
                            }
                        }
                    }
                    return
                }
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeData) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeData, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let url = data as? URL, self?.isGpxUrl(url) == true {
                                self?.loadAndSaveGpx(from: url)
                            } else if let fileData = data as? Data,
                                      let text = String(data: fileData, encoding: .utf8),
                                      text.trimmingCharacters(in: .whitespacesAndNewlines).contains("<gpx") {
                                self?.saveGpxContentAndOpenApp(content: text)
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    private func isGpxUrl(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "gpx" || url.absoluteString.lowercased().contains("gpx")
    }

    private func loadAndSaveGpx(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            saveGpxContentAndOpenApp(content: content)
        }
    }

    private func saveGpxContentAndOpenApp(content: String) {
        guard let userDefaults = UserDefaults(suiteName: kAppGroupId) else { return }
        userDefaults.set(content, forKey: kPendingGpxContentKey)
        userDefaults.synchronize()
        if let url = URL(string: "\(kShareSchemePrefix):gpx") {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func saveAndRedirect() {
        let urlToShare = sharedUrl ?? contentText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !urlToShare.isEmpty else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        if let userDefaults = UserDefaults(suiteName: kAppGroupId) {
            userDefaults.set(urlToShare, forKey: kSharedUrlKey)
            userDefaults.synchronize()
        }

        if let url = URL(string: "\(kShareSchemePrefix):share") {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
        }

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
