import UIKit
final class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "splash_screen_logo"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ypBlack  // color changed
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            presentAuth()
        }
    }
    
    private func presentAuth() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        guard
            let nav = storyboard.instantiateViewController(withIdentifier: "AuthNavigationController")
                as? UINavigationController,
            let authVC = nav.viewControllers.first as? AuthViewController
        else {
            assertionFailure("AuthNavigationController не найден в storyboard")
            return
        }

        authVC.delegate = self
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
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


// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) {
            guard let token = self.storage.token else { return }
            self.fetchProfile(token: token)
        }
    }
}
