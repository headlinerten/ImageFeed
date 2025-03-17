import Foundation

enum Constants {
    static let accessKey = "aJUaH8GwlWgTaOW_79dn05DRlxF9D5ZAgFGjnRJ0WxM"
    static let secretKey = "hAxRgyczQQUkW4qHmuM7_NkpTyvfixiA9fsZToZWbts"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static var defaultBaseURL: URL {
        guard let url = URL(string: "https://api.unsplash.com") else {
            fatalError("Invalid URL: Unable to create URL from string")
        }
        return url
    }
}
