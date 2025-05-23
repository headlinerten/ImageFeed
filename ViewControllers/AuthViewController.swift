import UIKit
import ProgressHUD

final class AuthViewController: UIViewController {
    
    
    weak var delegate: AuthViewControllerDelegate?
    private let showWebViewSegueIdentifier = "showWebView"
    private let oauth2Service = OAuth2Service.shared
    
    @IBOutlet weak var entryButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        entryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        entryButton.accessibilityIdentifier = "Authenticate"
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webVC = segue.destination as? WebViewViewController
            else {
                assertionFailure("Не удалось подготовить \(showWebViewSegueIdentifier)")
                return
            }

            // Инъекция хелпера и презентера
            let authHelper = AuthHelper()
            let presenter = WebViewPresenter(authHelper: authHelper)
            webVC.presenter = presenter
            presenter.view = webVC
            webVC.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("Code: \(code)")
        
        UIBlockingProgressHUD.show()
        oauth2Service.fetchAuthToken(code: code) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()
            
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    print("Token: \(token)")
                    
                    if let navController = self.navigationController {
                        print("PopViewController")
                        navController.popViewController(animated: true)
                    } else {
                        print("dismiss")
                        vc.dismiss(animated: true)
                    }
                    
                    if self.delegate == nil {
                        print("AuthViewController delegate = nil")
                    } else {
                        print("delegate passed")
                        self.delegate?.didAuthenticate(self)
                    }
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    self.showAuthErrorAlert()
                }
            }
        }
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button") // 1
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button") // 2
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil) // 3
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black") // 4
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("Auth canceled by user")
        print("Auth is going through")
        vc.dismiss(animated: true)
        self.delegate?.didAuthenticate(self)
    }
    
    // MARK: - Метод для показа ошибки авторизации
    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
