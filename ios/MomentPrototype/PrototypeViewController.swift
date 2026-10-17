import UIKit
import WebKit

/// Hosts the HTML prototypes from `prototype/` full-screen in a web view.
/// Onboarding opens first; its "Time to capture a moment" notification opens the shuffle.
/// Shake the phone to switch between the two.
final class PrototypeViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    enum Page: String {
        case onboarding = "moment-onboarding"
        case shuffle = "moment-shuffle"
    }

    /// The onboarding notification links to the hosted shuffle prototype; inside the app we open the bundled copy instead.
    private static let shuffleArtifactID = "EtQFCy7PLEf65dx2ahok2i"

    private var webView: WKWebView!
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let content = config.userContentController
        content.addUserScript(WKUserScript(source: Self.appModeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        content.add(WeakMessageHandler(self), name: "haptic")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 10 / 255, green: 16 / 255, blue: 18 / 255, alpha: 1)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        haptics.prepare()
        load(.onboarding)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    func load(_ page: Page) {
        guard let url = Bundle.main.url(forResource: page.rawValue, withExtension: "html") else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    // MARK: Links

    private func open(_ url: URL) {
        if url.absoluteString.contains(Self.shuffleArtifactID) {
            load(.shuffle)
        } else {
            UIApplication.shared.open(url)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, url.scheme == "http" || url.scheme == "https" else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        open(url)
    }

    // target="_blank" links land here
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url { open(url) }
        return nil
    }

    // MARK: Haptics

    /// The prototypes call `navigator.vibrate(pattern)`; the injected script forwards the pattern here.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let pattern = (message.body as? [NSNumber])?.map(\.doubleValue) ?? []
        var offset = 0.0
        for (index, ms) in pattern.enumerated() {
            if index.isMultiple(of: 2), ms > 0 {
                let intensity = CGFloat(min(1, 0.35 + ms / 40))
                DispatchQueue.main.asyncAfter(deadline: .now() + offset / 1000) { [weak self] in
                    self?.haptics.impactOccurred(intensity: intensity)
                }
            }
            offset += ms
        }
    }

    // MARK: Shake to switch

    override var canBecomeFirstResponder: Bool { true }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake, presentedViewController == nil else { return }
        let sheet = UIAlertController(title: "Open prototype", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Onboarding", style: .default) { [weak self] _ in self?.load(.onboarding) })
        sheet.addAction(UIAlertAction(title: "Shuffle", style: .default) { [weak self] _ in self?.load(.shuffle) })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: App mode

    /// Hides the desktop control panel and the drawn phone frame so the prototype fills the real screen,
    /// and routes `navigator.vibrate` to native haptics.
    private static let appModeScript = #"""
    (function () {
      document.documentElement.classList.add('app');
      var meta = document.querySelector('meta[name="viewport"]');
      if (meta) meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
      var style = document.createElement('style');
      style.textContent = `
        html.app body { background: #0A1012; }
        html.app .panel { display: none !important; }
        html.app .stage { padding: 0 !important; gap: 0 !important; min-height: 100%; }
        html.app .phone {
          --h: 100dvh; height: 100dvh; width: 100vw; max-width: none;
          padding: 0; border-radius: 0; background: none; box-shadow: none;
          transition: height .5s cubic-bezier(.2,.8,.2,1);
        }
        html.app .screen { border-radius: 0; }
        html.app .status, html.app .island, html.app .homebar { display: none !important; }
        html.app .view { padding-top: 2.5cqh; }
        html.app .table { gap: 12px 10px; width: 100vw; }
        html.app .table:not(.friends-on) .fcol { display: none; }
        html.app .table.friends-on .phone { --h: calc(100dvh - 142px); height: calc(100dvh - 142px); }
        html.app .fphone { --fh: 120px; }
        html.app #v-group .q { font-size: 8.4cqw; }
        html.app .member.me .av, html.app .member.me .mname { --s: 16cqw; }
        html.app .member:not(.me) .av, html.app .member:not(.me) .mname { --s: 12cqw; }
        html.app .member .mglow { width: 36cqw; height: 36cqw; left: -18cqw; top: -18cqw; }
      `;
      document.head.appendChild(style);
      navigator.vibrate = function (p) {
        try { window.webkit.messageHandlers.haptic.postMessage(Array.isArray(p) ? p : [p]); } catch (e) {}
        return true;
      };
    })();
    """#
}

/// Avoids the retain cycle between WKUserContentController and the view controller.
private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) { self.target = target }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
