import Foundation

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func updateProfile()
    func updateAvatar()
    func didConfirmLogout()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let profileLogoutService: ProfileLogoutService
    
    init(profileService: ProfileService = .shared,
         profileImageService: ProfileImageService = .shared,
         profileLogoutService: ProfileLogoutService = .shared) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.profileLogoutService = profileLogoutService
    }
    
    func viewDidLoad() {
        updateProfile()
        updateAvatar()
        
        NotificationCenter.default.addObserver(
            forName: ProfileService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateProfile()
        }
        
        NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }
    
    func didTapLogout() {
        view?.showLogoutAlert()
        // Сообщаем View показать алерт
    }
    
    func didConfirmLogout() {
        guard let view = view else {
            print("Ошибка: view равно nil")
            return
        }
        profileLogoutService.logout()
        view.navigateToSplashScreen()
    }
    
    func updateProfile() {
        guard let profile = profileService.profile else {
            view?.displayProfile(name: "No Name", login: "No Login", bio: "No Bio")
            return
        }
        
        view?.displayProfile(
            name: profile.name.isEmpty ? "No Name" : profile.name,
            login: profile.loginName.isEmpty ? "No Login" : profile.loginName,
            bio: profile.bio?.isEmpty == false ? profile.bio : "No Bio"
        )
    }
    
    func updateAvatar() {
        guard let avatarURLString = profileImageService.avatarURL, !avatarURLString.isEmpty else {
            view?.displayAvatar(url: nil)
            return
        }
        
        guard let url = URL(string: avatarURLString) else {
            view?.displayAvatar(url: nil)
            return
        }
        
        view?.displayAvatar(url: url)
    }
}
