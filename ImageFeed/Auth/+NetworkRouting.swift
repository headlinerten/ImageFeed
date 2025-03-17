import UIKit

protocol NetworkRouting {
    func fetch( url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}

