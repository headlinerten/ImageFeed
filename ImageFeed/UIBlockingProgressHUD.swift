import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    // Получаем главное окно приложения
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    /// Показывает индикатор загрузки и блокирует пользовательское взаимодействие
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    /// Скрывает индикатор загрузки и восстанавливает пользовательское взаимодействие
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
