import UIKit
@preconcurrency import WebKit

// MARK: - Контроллер
final class WebViewViewController: UIViewController & WebViewViewControllerProtocol {

    weak var delegate: WebViewViewControllerDelegate?

    // MARK: ‑ Dependencies
    var presenter: WebViewPresenterProtocol?

    // MARK: ‑ IBOutlets
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var progressView: UIProgressView!

    // MARK: ‑ Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        presenter?.viewDidLoad()

        // KVO ‑ отслеживаем прогресс загрузки
        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil)
    }

    // MARK: ‑ WebViewViewControllerProtocol
    func load(request: URLRequest) {
        webView.load(request)
    }

    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }

    // MARK: ‑ KVO
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }

    // MARK: ‑ Вспомогательное
    private func code(from navigationAction: WKNavigationAction) -> String? {
        guard let url = navigationAction.request.url else { return nil }
        return presenter?.code(from: url)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if code(from: navigationAction) != nil {
        }
        decisionHandler(.allow)
    }
}
