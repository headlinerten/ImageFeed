import UIKit

final class ImagesListViewController: UIViewController {

    // MARK: – Outlets
    @IBOutlet private var tableView: UITableView!

    // MARK: – Data
    private var photos: [Photo] = []

    // MARK: – Obs
    private var imagesListObserver: NSObjectProtocol?

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = UIEdgeInsets(top: 12, left: 0,
                                              bottom: 12, right: 0)

        // подписка
        imagesListObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.updateTableViewAnimated()
            }

        // первая страница
        ImagesListService.shared.fetchPhotosNextPage()
    }

    deinit {
        if let obs = imagesListObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: – Animate update
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = ImagesListService.shared.photos
        let newCount = newPhotos.count

        photos = newPhotos

        if newCount > oldCount {
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            tableView.performBatchUpdates {
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        } else {
            if let visible = tableView.indexPathsForVisibleRows {
                tableView.reloadRows(at: visible, with: .none)
            }
        }
    }

    // MARK: – Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "ShowSingleImage",
            let vc = segue.destination as? SingleImageViewController,
            let index = sender as? IndexPath
        else { return }

        let photo = photos[index.row]
        vc.imageURL = URL(string: photo.largeImageURL)
    }
}

// MARK: – DataSource
extension ImagesListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ImagesListCell.reuseIdentifier,
                for: indexPath
            ) as? ImagesListCell
        else {
            return UITableViewCell()
        }

        cell.delegate = self
        cell.configure(with: photos[indexPath.row])
        return cell
    }
}

// MARK: – Delegate
extension ImagesListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        if indexPath.row + 1 == photos.count {
            ImagesListService.shared.fetchPhotosNextPage()
        }
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSingleImage",
                     sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {

        let photo = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16,
                                  bottom: 4, right: 16)

        let imageViewWidth = tableView.bounds.width
                              - insets.left - insets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + insets.top + insets.bottom
    }
}

extension ImagesListViewController: ImagesListCellDelegate {

    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        // Блокируем UI на время запроса
        UIBlockingProgressHUD.show()

        ImagesListService.shared.changeLike(photoId: photo.id,
                                            isLike: !photo.isLiked) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                // Синхронизируем локальный массив и перерисовываем конкретную ячейку
                self.photos = ImagesListService.shared.photos
                cell.setIsLiked(self.photos[indexPath.row].isLiked)

            case .failure(let error):
                // Показать алерт
                let alert = UIAlertController(
                    title: "Что‑то пошло не так",
                    message: "Не удалось изменить состояние лайка\n\(error.localizedDescription)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ок", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}
