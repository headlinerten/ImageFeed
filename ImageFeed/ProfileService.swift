import UIKit

final class ProfileService {
    // MARK: - Singleton
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - Храним полученный профиль для UI
    private(set) var profile: Profile?
    
    // MARK: - Переменные для защиты от гонок при выполнении запроса
    private var task: URLSessionTask?
    private var lastToken: String?
    
    // MARK: - Ошибки ProfileService
    enum ProfileError: Error {
        case invalidURL
        case invalidResponse
        case noData
    }
    
    // MARK: - Модель для декодирования ответа Unsplash GET /me
    struct ProfileResult: Codable {
        let username: String
        let firstName: String?
        let lastName: String?
        let bio: String?
        
        private enum CodingKeys: String, CodingKey {
            case username
            case firstName = "first_name"
            case lastName = "last_name"
            case bio
        }
    }
    
    // MARK: - Модель для UI
    struct Profile {
        let username: String
        let name: String
        let loginName: String
        let bio: String?
    }
    
    // MARK: - Получение профиля
    /// Метод fetchProfile выполняет GET-запрос к https://api.unsplash.com/me,
    /// устанавливая в заголовок HTTP авторизацию через Bearer token.
    /// Если уже выполняется предыдущий запрос, он будет отменён, чтобы избежать гонок.
    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        // Если есть выполняющаяся задача, отменяем её
        if let task = task {
            task.cancel()
        }
        lastToken = token
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            completion(.failure(ProfileError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Добавляем заголовок с авторизационным токеном
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let newTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Обработка результата на главном потоке
            DispatchQueue.main.async {
                defer {
                    self?.task = nil
                    self?.lastToken = nil
                }
                
                if let error = error {
                    completion(.failure(error))
                    print("Ошибка получения профиля: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    completion(.failure(ProfileError.invalidResponse))
                    print("Неверный HTTP ответ при получении профиля")
                    return
                }
                
                guard let data = data else {
                    completion(.failure(ProfileError.noData))
                    print("Данные профиля отсутствуют")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let profileResult = try decoder.decode(ProfileResult.self, from: data)
                    // Формируем полное имя из first_name и last_name
                    let name: String
                    if let firstName = profileResult.firstName, let lastName = profileResult.lastName {
                        name = "\(firstName) \(lastName)"
                    } else if let firstName = profileResult.firstName {
                        name = firstName
                    } else if let lastName = profileResult.lastName {
                        name = lastName
                    } else {
                        name = ""
                    }
                    // Формируем модель для UI
                    let profile = Profile(
                        username: profileResult.username,
                        name: name,
                        loginName: "@\(profileResult.username)",
                        bio: profileResult.bio
                    )
                    self?.profile = profile
                    completion(.success(profile))
                } catch {
                    completion(.failure(error))
                    print("[ProfileService.fetchProfile]: \(error)")
                }
            }
        }
        self.task = newTask
        newTask.resume()
    }
}

extension ProfileService {
    func reset() {
        profile = nil
        task?.cancel()
        task = nil
        lastToken = nil
    }
}
