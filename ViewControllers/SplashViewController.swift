import UIKit
final class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let showAuthenticationScreenSegueIdentifier = "showAuthenticationScreen"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Если токен уже есть – загружаем профиль
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            // Если токена нет, переходим на экран авторизации
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    // MARK: - Получение профиля
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token: token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("Профиль получен: \(profile)")
                // Запускаем запрос аватарки
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                // После получения профиля переходим на TabBarController (главный экран)
                self.switchTabBarController()
            case .failure(let error):
                print("Ошибка получения профиля: \(error)")
                // Здесь можно вывести сообщение об ошибке пользователю
                break
            }
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
        vc.dismiss(animated: true) {
            guard let token = self.storage.token else { return }
            self.fetchProfile(token: token)
        }
    }
}
