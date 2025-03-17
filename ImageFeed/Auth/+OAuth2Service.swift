import UIKit

final class OAuth2Service {
    
    // MARK: - Singleton
    static let shared = OAuth2Service()
    private let baseURL = "https://unsplash.com/oauth/token"
    private let storage = OAuth2TokenStorage()
    private init() {}
    
    
    
    // MARK: - Запрос Токена
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else {
            fatalError("Invalid base URL")
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
            fatalError("Failed to construct URL from components")
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
    
    // MARK: - Извлечение токена
    func fetchAuthToken(code: String, completion: @escaping (Result<String, OAuthError>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                    print(error.localizedDescription)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidHTTPResponse))
                    print("HTTP is wrong")
                }
                return
            }
            
            print(httpResponse.statusCode)
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                    print("Error \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidData))
                    print("Data is absent")
                }
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
                self.storage.token = responseBody.accessToken
                
                DispatchQueue.main.async {
                    completion(.success(responseBody.accessToken))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed(error)))
                    print(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
}
