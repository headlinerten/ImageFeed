import XCTest
@testable import ImageFeed
import Foundation

class ImagesListPresenterTests: XCTestCase {
    var sut: ImagesListPresenterSpy!
    var viewSpy: ImagesListViewControllerSpy!
    
    override func setUp() {
        super.setUp()
        viewSpy = ImagesListViewControllerSpy()
        sut = ImagesListPresenterSpy(view: viewSpy) // Передаем viewSpy в конструктор
    }
    
    override func tearDown() {
        sut = nil
        viewSpy = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(sut.viewDidLoadCalled, "viewDidLoad() should be called")
    }
    
    func testFetchPhotosNextPage() {
        // When
        sut.fetchPhotosNextPage()
        
        // Then
        XCTAssertTrue(sut.fetchPhotosNextPageCalled, "fetchPhotosNextPage() should be called")
    }
    
    func testChangeLike() {
        // Given
        let photoId = "testPhotoId"
        let isLike = true
        
        // When
        sut.changeLike(photoId: photoId, isLike: isLike) { _ in }
        
        // Then
        XCTAssertTrue(sut.changeLikeCalled, "changeLike() should be called")
        XCTAssertEqual(sut.changeLikePhotoId, photoId, "changeLike() should pass correct photoId")
        XCTAssertEqual(sut.changeLikeIsLike, isLike, "changeLike() should pass correct isLike")
    }
    
    func testPhotoAtIndexPath() {
        // Given
        let indexPath = IndexPath(row: 0, section: 0)
        sut.photos = [
            Photo(
                id: "testPhotoId",
                size: CGSize(width: 100, height: 100),
                createdAt: Date(),
                description: "Test Description",
                thumbImageURL: "thumbURL",
                largeImageURL: "largeURL",
                isLiked: false
            )
        ]
        
        // When
        let photo = sut.photo(at: indexPath)
        
        // Then
        XCTAssertTrue(sut.photoAtIndexPathCalled, "photo(at:) should be called")
        XCTAssertEqual(sut.photoAtIndexPath, indexPath, "photo(at:) should pass correct indexPath")
        XCTAssertEqual(photo.id, "testPhotoId", "photo(at:) should return correct photo")
    }
}

class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol // Не опциональное, но weak
    
    var photos: [Photo] = []
    
    var viewDidLoadCalled = false
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false
    var changeLikePhotoId: String?
    var changeLikeIsLike: Bool?
    var photoAtIndexPathCalled = false
    var photoAtIndexPath: IndexPath?
    
    // Добавляем конструктор
    init(view: ImagesListViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        changeLikeCalled = true
        changeLikePhotoId = photoId
        changeLikeIsLike = isLike
    }
    
    func photo(at indexPath: IndexPath) -> Photo {
        photoAtIndexPathCalled = true
        photoAtIndexPath = indexPath
        return photos[indexPath.row]
    }
}

