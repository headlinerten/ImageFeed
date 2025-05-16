
import UIKit

protocol ImagesListViewControllerProtocol: AnyObject {
    func updateTableViewAnimated(oldCount: Int, newCount: Int)
    func showLikeErrorAlert()
}

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    @IBOutlet  var tableView: UITableView!
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    var presenter: ImagesListPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if presenter == nil {
        let defaultPresenter = ImagesListPresenter(view: self)
        configure(defaultPresenter)
          }
        
        print("TableView is nil? \(tableView == nil)")
        print("Presenter is nil? \(presenter == nil)")
        
        presenter.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("[ImagesListViewController|prepare]: Invalid segue destination")
                return
            }
            let photo = presenter.photo(at: indexPath)
            if let url = URL(string: photo.largeImageURL) {
                viewController.imageURL = url
            }
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
    }
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        guard tableView.window != nil else {
            print("Предупреждение: таблица не в иерархии представлений")
            return
        }
        
        if oldCount != newCount && oldCount < newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in }
        } else if oldCount > newCount {
            print("Ошибка: oldCount (\(oldCount)) больше newCount (\(newCount))")
        }
    }
    internal func showLikeErrorAlert() {
        let alert = UIAlertController(title: "Ошибка", message: "Не удалось поставить лайк(", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ImagesListCell.reuseIdentifier,
                for: indexPath
            ) as? ImagesListCell
        else {
            return UITableViewCell()
        }
        
        let photo = presenter.photo(at: indexPath)
        cell.configure(with: photo)
        cell.delegate = self
        cell.setIsLiked(photo.isLiked)
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = presenter.photo(at: indexPath)
        let tableWidth = tableView.bounds.width - tableView.layoutMargins.left - tableView.layoutMargins.right
        return (photo.size.height / photo.size.width) * tableWidth + 8
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == presenter.photos.count {
            presenter.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = presenter.photo(at: indexPath)
        
        UIBlockingProgressHUD.show()
        presenter.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                switch result {
                case .success:
                    cell.setIsLiked(!photo.isLiked)
                case .failure:
                    self.showLikeErrorAlert()
                }
            }
        }
    }
}
