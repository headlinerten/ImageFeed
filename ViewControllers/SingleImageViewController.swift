import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    var imageURL: URL? {
        didSet {
            guard isViewLoaded, let imageURL else { return }
            loadImage()
        }
    }
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
        
        if imageURL != nil { loadImage() }
    }
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }

    private func setImage(from url: URL) {
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url) { [weak self] _ in
            guard let self, let image = self.imageView.image else { return }
            self.imageView.frame.size = image.size
            self.rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        centerImageInScrollView()
    }
    
    private func centerImageInScrollView() {
        let scrollViewSize = scrollView.bounds.size
        let imageViewSize = imageView.frame.size
        
        let verticalInset = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalInset = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        let offset: CGFloat = 40
        
        let topInset = max(verticalInset - offset, 0)
        let bottomInset = verticalInset + offset
        
        scrollView.contentInset = UIEdgeInsets(top: topInset, left: horizontalInset, bottom: bottomInset, right: horizontalInset)
    }
    
    private func loadImage() {
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)
            case .failure:
                self.showError()
            }
        }
    }
    
    private func rescaleAndCenter(image: UIImage) {
        let scale = scrollView.bounds.width / image.size.width
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
        centerImage()
    }

    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame

        frameToCenter.origin.x = frameToCenter.width < boundsSize.width
            ? (boundsSize.width - frameToCenter.width) / 2 : 0
        frameToCenter.origin.y = frameToCenter.height < boundsSize.height
            ? (boundsSize.height - frameToCenter.height) / 2 : 0
        imageView.frame = frameToCenter
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Что‑то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { _ in
            self.loadImage()
        })
        present(alert, animated: true)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }
}
