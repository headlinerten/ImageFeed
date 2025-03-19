import UIKit
import Foundation

final class AuthViewController: UIViewController {
    
    
    weak var delegate: AuthViewControllerDelegate?
    private let showWebViewSegueIdentifier = "showWebView"
    private let oauth2Service = OAuth2Service.shared
    
    @IBOutlet weak var entryButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure()
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("Code: \(code)")
        
        oauth2Service.fetchAuthToken(code: code) { [weak self] result in
            guard let self else { return }
            
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
            title: "Ошибка авторизации",
            message: "Не удалось выполнить вход. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
