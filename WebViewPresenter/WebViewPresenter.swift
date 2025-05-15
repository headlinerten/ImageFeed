import Foundation

final class WebViewPresenter: WebViewPresenterProtocol {

    weak var view: WebViewViewControllerProtocol?

    func viewDidLoad() {
        view?.setProgressValue(0)
        view?.setProgressHidden(false)

        guard
            var components = URLComponents(string: Constants.unsplashAuthorizeURLString)
        else { return }

        components.queryItems = [
            URLQueryItem(name: "client_id",     value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri",  value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope",         value: Constants.accessScope)
        ]

        guard let url = components.url else { return }
        view?.load(request: URLRequest(url: url))
    }

    func didUpdateProgressValue(_ newValue: Double) {
        let progress = Float(newValue)
        view?.setProgressValue(progress)
        view?.setProgressHidden(shouldHideProgress(for: progress))
    }

    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }

    func code(from url: URL) -> String? {
        guard
            let components = URLComponents(string: url.absoluteString),
            components.path == "/oauth/authorize/native",
            let item = components.queryItems?.first(where: { $0.name == "code" })
        else { return nil }

        return item.value
    }
}
