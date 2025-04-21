import UIKit

final class OAuth2Service {
    
    // MARK: - Singleton
    static let shared = OAuth2Service()
    private let baseURL = "https://unsplash.com/oauth/token"
    private let storage = OAuth2TokenStorage()
    private init() {}
    
    // MARK: - Защита от гонок
    private var task: URLSessionTask?
    private var lastCode: String?
    
    // MARK: - Запрос Токена
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else {
            print("Ошибка: неверный базовый URL")
            return nil
        }
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = "/oauth/token"
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components.url else {
            print("Ошибка: не удалось сформировать URL из компонентов")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    enum OAuthError: Error {
        case invalidRequest
        case networkError(Error)
        case invalidHTTPResponse
        case invalidStatusCode(Int)
        case invalidData
        case decodingFailed(Error)
        
    }
    
    // MARK: - Получение токена с обработкой гонок
    func fetchAuthToken(code: String, completion: @escaping (Result<String, OAuthError>) -> Void) {
        // Гарантируем, что вызов происходит из главного потока для безопасного доступа к task и lastCode
        assert(Thread.isMainThread)
        
        // Если уже выполняется запрос
        if let _ = task {
            if lastCode != code {
                // Если код отличается, предыдущий запрос больше не актуален — отменяем его
                task?.cancel()
            } else {
                // Если код совпадает, значит запрос уже выполняется — сообщаем об ошибке
                completion(.failure(.invalidRequest))
                return
            }
        } else {
            // Если задачи нет, но lastCode уже равен переданному коду — тоже считаем, что повторный запрос не нужен
            if lastCode == code {
                completion(.failure(.invalidRequest))
                return
            }
        }
        
        // Запоминаем новый код
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        let newTask = URLSession.shared.objectTask(
            for: request
        ) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self else { return }
                defer {
                    self.task = nil
                    self.lastCode = nil
                }
                
                switch result {
                case .success(let body):
                    self.storage.token = body.accessToken
                    completion(.success(body.accessToken))
                    
                case .failure(let error):
                    print("[OAuth2Service.fetchAuthToken]: \(error)")
                    
                    if error is DecodingError {
                        completion(.failure(.decodingFailed(error)))
                    } else {
                        completion(.failure(.networkError(error)))
                    }
                }
            }
        }
        
        task = newTask
        newTask.resume()
    }
}
