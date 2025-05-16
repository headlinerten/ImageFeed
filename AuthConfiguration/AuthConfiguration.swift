import Foundation

enum Constants {
    static let accessKey = "aJUaH8GwlWgTaOW_79dn05DRlxF9D5ZAgFGjnRJ0WxM"
    static let secretKey = "hAxRgyczQQUkW4qHmuM7_NkpTyvfixiA9fsZToZWbts"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static var defaultBaseURL: URL? {
        return URL(string: "https://api.unsplash.com")
    }
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL
    let authURLString: String
    
    init(
        accessKey: String,
        secretKey: String,
        redirectURI: String,
        accessScope: String,
        authURLString: String,
        defaultBaseURL: URL
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.accessScope = accessScope
        self.defaultBaseURL = defaultBaseURL
        self.authURLString = authURLString
    }
    
    static var standard: AuthConfiguration {
        guard let baseURL = Constants.defaultBaseURL else {
            fatalError("Invalid defaultBaseURL")
        }
        return AuthConfiguration(
            accessKey:     Constants.accessKey,
            secretKey:     Constants.secretKey,
            redirectURI:   Constants.redirectURI,
            accessScope:   Constants.accessScope,
            authURLString: Constants.unsplashAuthorizeURLString,
            defaultBaseURL: baseURL
        )
    }
}
