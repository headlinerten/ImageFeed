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
            
            let newTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                // Переключаемся на главный поток для обработки результата
                DispatchQueue.main.async {
                    // Обнуляем task и lastCode после завершения запроса
                    defer {
                        self?.task = nil
                        self?.lastCode = nil
                    }
                    
                    if let error = error {
                        completion(.failure(.networkError(error)))
                        print(error.localizedDescription)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(.failure(.invalidHTTPResponse))
                        print("HTTP is wrong")
                        return
                    }
                    
                    print(httpResponse.statusCode)
                    
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                        print("Error \(httpResponse.statusCode)")
                        return
                    }
                    
                    guard let data = data else {
                        completion(.failure(.invalidData))
                        print("Data is absent")
                        return
                    }
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("JSON String: \(jsonString)")
                    } else {
                        print("Invalid JSON")
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                        self?.storage.token = responseBody.accessToken
                        
                        completion(.success(responseBody.accessToken))
                    } catch {
                        completion(.failure(.decodingFailed(error)))
                        print(error.localizedDescription)
                    }
                }
            }
            // Фиксируем новую задачу и запускаем её
            task = newTask
            newTask.resume()
        }
    }
