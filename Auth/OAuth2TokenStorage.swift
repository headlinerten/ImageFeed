import UIKit
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    
    private let key = "AuthToken"
    
    var token: String? {
        get {
            KeychainWrapper.standard.string(forKey: key)
        }
        set {
            if let value = newValue {
                KeychainWrapper.standard.set(value, forKey: key, withAccessibility: .whenUnlockedThisDeviceOnly)
            } else {
                KeychainWrapper.standard.removeObject(forKey: key)
            }
        }
    }
}
