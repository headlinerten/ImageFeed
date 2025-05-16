import Foundation

// MARK: - Модель данных для профиля
struct ProfileResult: Codable {
    let username: String
    let name: String?
    let firstName: String?
    let lastName: String?
    let bio: String?
    
    
    enum CodingKeys: String, CodingKey {
        case username
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

struct Profile: Equatable {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    
    init(profileResult: ProfileResult) {
        self.username = profileResult.username
        self.name = [profileResult.firstName, profileResult.lastName] .compactMap { $0 }.joined(separator: " ")
        self.loginName = "@\(profileResult.username)"
        self.bio = profileResult.bio
    }
}
// MARK: - Ошибки сети для профиля
enum ProfileNetworkError: Error {
    case requestCancelled
    case urlSessionError
    case urlSessionRequestError
    case missingToken
}

final class ProfileService {
    
    private var currentTask: URLSessionTask?
    static var shared = ProfileService()
    private init() {}
   var profile: Profile? {
        didSet {
            NotificationCenter.default.post(
                name: ProfileService.didChangeNotification,
                object: self
            )
        }
    }
    static let didChangeNotification = Notification.Name("ProfileServiceDidChange")
    
    func updateProfile(_ profile: Profile) {
        self.profile = profile
        NotificationCenter.default.post(name: ProfileService.didChangeNotification, object: nil)
    }
    // MARK: - Создание запроса с авторизацией
    private func createAuthRequest(url: URL, token: String) -> URLRequest? {
        print("[ProfileService|createAuthRequest]: Создаём запрос с токеном: \(token)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    func clearProfile() {
        profile = nil
        NotificationCenter.default.post(name: ProfileService.didChangeNotification, object: self)
        print("Профиль удален")
    }
    
    // MARK: - Запрос профиля пользователя
    func fetchProfileInfo(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        
        print("[ProfileService|fetchProfile]: Отправка запроса...")
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService|fetchProfile]: Ошибка интернет соединения - не создаётся URL")
            completion(.failure(ProfileNetworkError.urlSessionError))
            return
        }
        
        
        print("URL successfully created: \(url)")
        guard let request = createAuthRequest(url: url, token: token) else {
            print("[ProfileService|fetchProfile]: Ошибка интернет соединения - не создаётся URLRequest")
            completion(.failure(ProfileNetworkError.requestCancelled))
            return
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let profileResult):
                print("[ProfileService|fetchProfile]: Данные успешно декодированы: \(profileResult)")
                let profile = Profile(profileResult: profileResult)
                self?.profile = profile
                completion(.success(profile))
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                
            case .failure(let error):
                print("[ProfileService|fetchProfile]: Ошибка декодирования - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        self.currentTask = task
        task.resume()
    }
    
    func reset() {
            profile = nil
        }
}
