import UIKit

final class OAuth2TokenStorage {
    
    var token: String? {
        get {
            UserDefaults.standard.string(forKey: "AuthToken")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "AuthToken")
        }
    }
}

