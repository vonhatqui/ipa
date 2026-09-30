import SwiftUI
import WebKit

struct PhantomWebPanelView: UIViewControllerRepresentable {
    @ObservedObject var licenseManager: CheatStoreLicenseManager = .shared

    func makeUIViewController(context: Context) -> PhantomWebPanelViewController {
        let vc = PhantomWebPanelViewController()
        vc.licenseManager = licenseManager
        return vc
    }

    func updateUIViewController(_ uiViewController: PhantomWebPanelViewController, context: Context) {
        uiViewController.licenseManager = licenseManager
    }
}

final class PhantomWebPanelViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    var licenseManager: CheatStoreLicenseManager = .shared
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let contentController = WKUserContentController()
        contentController.add(self, name: "bytrix")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = self

        view.addSubview(webView)
        loadWebPanel()
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func findWebPanelDirectory() -> URL? {
        let fileManager = FileManager.default

        // 1. Check in Bundle AppCore/WebPanel
        if let resURL = Bundle.main.resourceURL {
            let p1 = resURL.appendingPathComponent("AppCore/WebPanel")
            if fileManager.fileExists(atPath: p1.appendingPathComponent("current-ui.html").path) {
                return p1
            }
            let p2 = resURL.appendingPathComponent("WebPanel")
            if fileManager.fileExists(atPath: p2.appendingPathComponent("current-ui.html").path) {
                return p2
            }
        }

        // 2. Check Bundle.main URL for current-ui.html
        if let directURL = Bundle.main.url(forResource: "current-ui", withExtension: "html", subdirectory: "AppCore/WebPanel") {
            return directURL.deletingLastPathComponent()
        }

        return nil
    }

    private func loadWebPanel() {
        guard let panelDir = findWebPanelDirectory() else {
            print("[PhantomWebPanel] Khong tim thay thu muc AppCore/WebPanel!")
            return
        }

        let htmlURL = panelDir.appendingPathComponent("current-ui.html")
        print("[PhantomWebPanel] Dang load 0xCheats Web UI: \(htmlURL.path)")
        webView.loadFileURL(htmlURL, allowingReadAccessTo: panelDir)
    }

    func sendToWeb(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonStr = String(data: data, encoding: .utf8) else { return }

        let js = """
        (function() {
            var m = \(jsonStr);
            if (window.bytrixReceive) {
                window.bytrixReceive(m);
            } else {
                (window.__bxPending = window.__bxPending || []).push(m);
            }
        })();
        """

        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("[PhantomWebPanel] JS eval error: \(error)")
                }
            }
        }
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "bytrix" else { return }

        if let dict = message.body as? [String: Any], let type = dict["type"] as? String {
            handleNativeMessage(type: type, payload: dict)
        } else if let type = message.body as? String {
            handleNativeMessage(type: type, payload: [:])
        }
    }

    private func handleNativeMessage(type: String, payload: [String: Any]) {
        switch type {
        case "ready":
            let route = licenseManager.isActivated ? "main" : "auth"
            sendToWeb([
                "type": "boot",
                "fastUi": true,
                "prefill": licenseManager.activeKey,
                "route": route,
                "brand": [
                    "name": "CheatStore VN",
                    "tagline": "0xCheats Engine",
                    "hello": "CheatStore VN"
                ]
            ])

        case "license":
            if let key = payload["key"] as? String {
                let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
                Task {
                    let success = await self.licenseManager.activateKey(trimmed)
                    await MainActor.run {
                        if success {
                            CheatStoreSoundManager.shared.playSuccessSound()
                            self.sendToWeb([
                                "type": "authResult",
                                "ok": true,
                                "user": "CheatStore VIP",
                                "key": trimmed,
                                "info": [
                                    "plan": self.licenseManager.planName,
                                    "expiry": self.licenseManager.formattedRemainingTime,
                                    "status": "Active"
                                ]
                            ])
                        } else {
                            let msg = self.licenseManager.errorMessage ?? "Key khong hop le hoac da het han!"
                            self.sendToWeb([
                                "type": "authResult",
                                "ok": false,
                                "error": msg
                            ])
                        }
                    }
                }
            }

        case "paste":
            let text = UIPasteboard.general.string ?? ""
            sendToWeb(["type": "pasted", "text": text])

        case "copy":
            if let text = payload["text"] as? String {
                UIPasteboard.general.string = text
            }

        case "clean", "restore":
            DispatchQueue.global(qos: .userInitiated).async {
                _ = DevicePatchService.cleanRestoreAllModifications()
                DispatchQueue.main.async { [weak self] in
                    if type == "clean" {
                        self?.sendToWeb(["type": "cleanResult", "ok": true])
                    } else {
                        self?.sendToWeb(["type": "restoreResult", "ok": true])
                    }
                }
            }

        case "signOut":
            licenseManager.deactivate()

        case "openURL":
            if let urlStr = payload["url"] as? String, let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }

        default:
            print("[PhantomWebPanel] Unhandled message type: \(type)")
        }
    }
}
