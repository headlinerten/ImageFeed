import UIKit
import Foundation
import Kingfisher
import SwiftKeychainWrapper

protocol ProfileViewProtocol: AnyObject {
    func displayProfile(name: String, login: String, bio: String?)
    func displayAvatar(url: URL?)
    func navigateToSplashScreen()
    func showLogoutAlert()
}

final class ProfileViewController: UIViewController, ProfileViewProtocol {
    // MARK: - UI Elements
     let nameLabel = UILabel()
     let loginLabel = UILabel()
     let descriptionLabel = UILabel()
     let profileImage = UIImageView()
     var presenter: ProfilePresenterProtocol!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ProfileViewController was loaded")
        
        presenter = ProfilePresenter()
        presenter.view = self
        
        view.backgroundColor = .ypBlack
        profileImage.clipsToBounds = true
        setupUI()
        
        presenter.viewDidLoad()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Настройка profileImage
        profileImage.tintColor = .gray
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImage)
        NSLayoutConstraint.activate([
            profileImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        // Настройка logoutButton
        let logoutButton = UIButton(type: .system)
        logoutButton.setImage(UIImage(named: "logoutButton"), for: .normal)
        logoutButton.tintColor = .ypRed
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            logoutButton.centerYAnchor.constraint(equalTo: profileImage.centerYAnchor),
        ])
        logoutButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        // Настройка nameLabel
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 8),
        ])
        
        // Настройка loginLabel
        loginLabel.textColor = .lightGray
        loginLabel.font = .systemFont(ofSize: 13, weight: .regular)
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
        NSLayoutConstraint.activate([
            loginLabel.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
        ])
        
        // Настройка descriptionLabel
        descriptionLabel.textColor = .white
        descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8),
        ])
    }
    
    @objc
     func didTapButton() {
        presenter.didTapLogout() // Сообщаем презентеру о нажатии на кнопку
    }
    
    // MARK: - ProfileViewProtocol
    func displayProfile(name: String, login: String, bio: String?) {
        nameLabel.text = name
        loginLabel.text = login
        descriptionLabel.text = bio
    }
    
    func displayAvatar(url: URL?) {
        if let url = url {
            let processor = RoundCornerImageProcessor(cornerRadius: 50, backgroundColor: .ypBlack)
            profileImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "UserPhoto"),
                options: [
                    .processor(processor),
                    .transition(.fade(0.3))
                ]
            ) { result in
                switch result {
                case .success(let value):
                    print("[ProfileViewController|updateAvatar]: Аватарка успешно загружена с URL: \(value.source.url?.absoluteString ?? "неизвестно")")
                case .failure(let error):
                    print("[ProfileViewController|updateAvatar]: Ошибка при загрузке аватарки: \(error.localizedDescription)")
                    self.profileImage.image = UIImage(named: "UserPhoto")
                }
            }
        } else {
            profileImage.image = UIImage(named: "UserPhoto")
        }
    }
    
    func navigateToSplashScreen() {
        let splashViewController = SplashViewController()
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Нет доступного окна")
        }
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
    }
    func showLogoutAlert() {
        let alert = UIAlertController(title: "Пока, пока!", message: "Уверены, что хотите выйти?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            self?.presenter.didConfirmLogout() // Сообщаем презентеру о подтверждении выхода
        }
        
        let noAction = UIAlertAction(title: "Нет", style: .cancel)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true)
    }
}
