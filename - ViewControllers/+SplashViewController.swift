import UIKit
final class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage()
    private let showAuthenticationScreenSegueIdentifier = "showAuthenticationScreen"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuth()
    }
    // MARK: - Аутентификация
    private func checkAuth() {
        if storage.token != nil {
            switchTabBarController()
        } else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    // MARK: - Навигация
    private func switchTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Ошибка конфигурации")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        window.rootViewController = tabBarController
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard let navigationController = segue.destination as? UINavigationController,
                  let authViewController = navigationController.viewControllers.first as? AuthViewController else {
                assertionFailure("Не удалось перейти на AuthViewController")
                return
            }
            authViewController.delegate = self
            print("delegate in SplashViewController: \(self)")
            print("delegate AuthViewController: \(String(describing: authViewController.delegate))")
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            self?.switchTabBarController()
        }
    }
}
