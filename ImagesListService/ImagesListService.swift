import Foundation

// MARK: - DTO, приходящий из сети (строго под JSON)
struct PhotoResult: Decodable {
    let id: String
    let width: Int
    let height: Int
    let created_at: String?
    let description: String?
    let liked_by_user: Bool
    let urls: URLS
    
    struct URLS: Decodable {
        let thumb: String
        let full: String
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
       ISO8601DateFormatter()
    }()
    
    // конвертация в UI‑модель
    func toUIModel() -> Photo {
        let createdDate = Self.dateFormatter.date(from: created_at ?? "")
        return Photo(
            id: id,
            size: CGSize(width: width, height: height),
            createdAt: createdDate,
            description: description,
            thumbImageURL: urls.thumb,
            largeImageURL: urls.full,
            isLiked: liked_by_user
        )
    }
}

// MARK: - UI‑модель
struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let description: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
}

// MARK: - Сервис
final class ImagesListService {
    
    // singleton
    static let shared = ImagesListService()
    private init() {}
    
    // данные наружу
    private(set) var photos: [Photo] = []
    
    // paging state
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    
    // нотификация
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    // публичный метод
    func fetchPhotosNextPage() {
        // если уже идёт запрос — выходим
        if task != nil { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        let perPage  = 10
        
        guard let request = makePhotosRequest(page: nextPage, perPage: perPage) else {
            assertionFailure("Не удалось создать request")
            return
        }
        
        task = URLSession.shared.objectTask(for: request) { [weak self]
            (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            defer { self.task = nil }
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { $0.toUIModel() }
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self)
            case .failure(let error):
                print("[ImagesListService.fetch]: \(error)")
            }
        }
        task?.resume()
    }
    
    // MARK: make request
    private func makePhotosRequest(page: Int, perPage: Int) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.unsplash.com"
        components.path   = "/photos"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    // MARK: – Like / Unlike
    func changeLike(photoId: String,
                    isLike: Bool,
                    completion: @escaping (Result<Void, Error>) -> Void) {

        // 1. Формируем URL
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.unsplash.com"
        components.path   = "/photos/\(photoId)/like"

        guard let url = components.url else {
            completion(.failure(NetworkError.urlSessionError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"

        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 2. Запускаем
        let task = URLSession.shared.objectTask(for: request) { [weak self]
            (result: Result<LikeResponse,Error>) in
            guard let self else { return }

            switch result {
            case .success(let body):
                // 3. Обновляем локальную модель на main
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let old = self.photos[index]
                        let updated = Photo(
                            id: old.id,
                            size: old.size,
                            createdAt: old.createdAt,
                            description: old.description,
                            thumbImageURL: old.thumbImageURL,
                            largeImageURL: old.largeImageURL,
                            isLiked: body.photo.liked_by_user
                        )
                        self.photos[index] = updated
                        
                        // нотификация, чтобы ячейка перерисовалась
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self)
                    }
                    completion(.success(()))
                }
            case .failure(let error):
                print("[ImagesListService.changeLike]: Ошибка при изменении лайка для фото ID \(photoId) - \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }

    private struct LikeResponse: Decodable {
        let photo: PhotoLikeState
        struct PhotoLikeState: Decodable {
            let liked_by_user: Bool
        }
    }
}

extension ImagesListService {
    func reset() {
        photos = []
        lastLoadedPage = nil
        task?.cancel()
        task = nil
    }
}
