import Foundation

enum NetworkError: Error {
    case urlSessionError
    case urlRequestError(Error)
    case httpStatusCode(Int)
}

extension URLSession {

    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {

        let fulfillOnMain: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        let task = dataTask(with: request) { data, response, error in
            let log = "[dataTask]"
            if let error {                       // urlRequestError
                print("\(log): \(error)")
                fulfillOnMain(.failure(NetworkError.urlRequestError(error)))
                return
            }
            if let status = (response as? HTTPURLResponse)?.statusCode,
               !(200..<300).contains(status) {  // httpStatusCode
                print("\(log): http \(status)")
                fulfillOnMain(.failure(NetworkError.httpStatusCode(status)))
                return
            }
            guard let data else {                // urlSessionError
                print("\(log): no data")
                fulfillOnMain(.failure(NetworkError.urlSessionError))
                return
            }
            fulfillOnMain(.success(data))
        }
        return task
    }

    // 2. Новый универсальный метод
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {

        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let object = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    print("[objectTask]: decode – \(error)\nRAW: \(String(data: data, encoding: .utf8) ?? "")")
                    completion(.failure(error))
                }

            case .failure(let error):
                print("[objectTask]: upstream – \(error)")
                completion(.failure(error))
            }
        }
        return task
    }
}
