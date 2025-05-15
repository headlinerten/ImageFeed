import Foundation

final class ProfileImageService {
    // MARK: - Singleton
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private init() {}
    
    // MARK: - Свойства для защиты от гонок
    private var task: URLSessionTask?
    private var lastUsername: String?
    
    // MARK: - Храним URL аватарки, полученной при успешном запросе
    private(set) var avatarURL: String?
    
    // MARK: - Модель для декодирования ответа GET /users/:username
    struct UserResult: Codable {
        let profileImage: ProfileImage
        
        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
    }
    
    struct ProfileImage: Codable {
        let small: String
    }
    
    // MARK: - Ошибки ProfileImageService
    enum ProfileImageError: Error {
        case duplicateRequest
        case invalidURL
        case noToken
        case invalidResponse
        case noData
    }
    
    // MARK: - Получение URL аватарки
    func fetchProfileImageURL(username: String,
                              _ completion: @escaping (Result<String, Error>) -> Void) {
        // Проверяем, выполняется ли уже запрос
        if let currentTask = task {
            if lastUsername != username {
                // Если имя пользователя отличается от предыдущего запроса — отменяем предыдущий запрос
                currentTask.cancel()
            } else {
                // Если запрос для того же пользователя уже выполняется, возвращаем ошибку
                print("[ProfileImageService.fetchProfileImageURL]: duplicateRequest")
                completion(.failure(ProfileImageError.duplicateRequest))
                return
            }
        } else {
            // Если task == nil, но lastUsername уже равен username — считаем, что такой запрос уже был выполнен ранее
            if lastUsername == username {
                print("[ProfileImageService.fetchProfileImageURL]: duplicateRequest")
                completion(.failure(ProfileImageError.duplicateRequest))
                return
            }
        }
        
        // Запоминаем имя пользователя для которого сейчас выполняется запрос
        lastUsername = username
        
        // Формируем URL запроса. По спецификации Unsplash, для получения публичной информации о пользователе используется GET /users/:username.
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService.fetchProfileImageURL]: invalidURL")
            completion(.failure(ProfileImageError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Получаем токен из OAuth2TokenStorage.
        // Если в вашем проекте OAuth2TokenStorage реализован как синглтон, используйте его (например, OAuth2TokenStorage.shared.token)
        // Здесь приведён пример получения через инстанс; измените под свою реализацию, если требуется.
        guard let token = OAuth2TokenStorage().token else {
            print("[ProfileImageService.fetchProfileImageURL]: noToken")
            completion(.failure(ProfileImageError.noToken))
            return
        }
        // Добавляем заголовок авторизации
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Создаем задачу запроса
        let newTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Гарантируем обнуление task и lastUsername после завершения
                defer {
                    self?.task = nil
                    self?.lastUsername = nil
                }
                
                if let error = error {
                    print("[ProfileImageService.fetchProfileImageURL]: \(error)")
                    completion(.failure(error))
                    return
                }
                
                // Проверяем HTTP-ответ
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    print("[ProfileImageService.fetchProfileImageURL]: invalidResponse")
                    completion(.failure(ProfileImageError.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    print("[ProfileImageService.fetchProfileImageURL]: noData")
                    completion(.failure(ProfileImageError.noData))
                    return
                }
                
                // Декодируем ответ
                do {
                    let decoder = JSONDecoder()
                    let userResult = try decoder.decode(UserResult.self, from: data)
                    let imageURL = userResult.profileImage.small
                    // Сохраняем URL в свойство
                    self?.avatarURL = imageURL
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": imageURL]
                    )
                    completion(.success(imageURL))
                } catch {
                    print("[ProfileImageService.fetchProfileImageURL]: \(error)")
                    completion(.failure(error))
                }
            }
        }
        self.task = newTask
        newTask.resume()
    }
}

extension ProfileImageService {
    func reset() {
        avatarURL = nil
        task?.cancel()
        task = nil
        lastUsername = nil
    }
}
