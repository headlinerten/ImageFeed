import Foundation
import WebKit

final class ProfileLogoutService {

    static let shared = ProfileLogoutService()
    private init() {}

    /// Полный сброс пользовательских данных
    func logout() {
        // 1. удаляем токен
        OAuth2TokenStorage().token = nil

        // 2. чистим куки Web‑просмотра
        cleanCookies()

        // 3. сбрасываем синглтоны‑модели
        ProfileService.shared.reset()
        ProfileImageService.shared.reset()
        ImagesListService.shared.reset()

        // 4. возвращаемся на стартовый экран
        switchToSplash()
    }

    // MARK: – Private

    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)

        let dataStore = WKWebsiteDataStore.default()
        let allTypes  = WKWebsiteDataStore.allWebsiteDataTypes()

        dataStore.fetchDataRecords(ofTypes: allTypes) { records in
            dataStore.removeData(ofTypes: allTypes,
                                 for: records,
                                 completionHandler: {})
        }
    }

    private func switchToSplash() {
        guard let window = UIApplication.shared.windows.first else { return }
        let splash = SplashViewController()
        window.rootViewController = splash
    }
}
