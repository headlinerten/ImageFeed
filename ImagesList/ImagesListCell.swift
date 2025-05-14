import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    weak var delegate: ImagesListCellDelegate?

    @IBOutlet private var cellImage: UIImageView!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var dateLabel: UILabel!

    // MARK: - Actions
    @IBAction private func likeButtonClicked(_ sender: UIButton) {
        delegate?.imageListCellDidTapLike(self)
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = UIImage(named: "placeholder")
        likeButton.setImage(UIImage(named: "No Active"), for: .normal)
    }

    // MARK: - Configure
    func configure(with photo: Photo) {
        cellImage.kf.indicatorType = .activity
        cellImage.kf.setImage(
            with: URL(string: photo.thumbImageURL),
            placeholder: UIImage(named: "placeholder")) { [weak self] result in

            guard let self,
                  case .success(let v) = result,
                  let tableView = self.window?.viewWithTag(0) as? UITableView,
                  let index = tableView.indexPath(for: self) else { return }

            // Обновим высоту строки
            tableView.reloadRows(at: [index], with: .automatic)
        }

        if let created = photo.createdAt {
            let df = DateFormatter()
            df.dateFormat = "dd MMMM yyyy"
            df.locale = Locale(identifier: "ru_RU")
            dateLabel.text = df.string(from: created)
        } else {
            dateLabel.text = ""
        }

        setIsLiked(photo.isLiked)
    }

    func setIsLiked(_ isLiked: Bool) {
        let name = isLiked ? "Active" : "No Active"
        likeButton.setImage(UIImage(named: name), for: .normal)
    }
}
