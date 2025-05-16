import XCTest
@testable import ImageFeed
import Foundation

class ImagesListViewControllerTests: XCTestCase {
    var sut: ImagesListViewController!
    var presenterSpy: ImagesListPresenterSpy!
    
    override func setUp() {
        super.setUp()
        let viewSpy = ImagesListViewControllerSpy()
        presenterSpy = ImagesListPresenterSpy(view: viewSpy)
        sut = ImagesListViewController()
        sut.tableView = TableViewSpy()
        sut.presenter = presenterSpy
    }
    
    override func tearDown() {
        sut = nil
        presenterSpy = nil
        super.tearDown()
    }
    
    func testViewDidLoad_CallsPresenterViewDidLoad() {
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(presenterSpy.viewDidLoadCalled, "viewDidLoad() should be called on presenter")
    }
    
    func testUpdateTableViewAnimated_InsertsRows() {
        // Given
        let tableViewSpy = TableViewSpy()
        sut.tableView = tableViewSpy
        
        // Добавляем таблицу в иерархию представлений
        let window = UIWindow()
        window.addSubview(sut.view)
        
        // When
        sut.updateTableViewAnimated(oldCount: 2, newCount: 5)
        
        // Then
        XCTAssertTrue(tableViewSpy.insertRowsCalled, "insertRows should be called")
        XCTAssertEqual(tableViewSpy.insertedIndexPaths.count, 3, "Three new rows should be inserted")
        XCTAssertEqual(tableViewSpy.insertedIndexPaths, [
            IndexPath(row: 2, section: 0),
            IndexPath(row: 3, section: 0),
            IndexPath(row: 4, section: 0)
        ], "Correct index paths should be inserted")
    }
    
    func testUpdateTableViewAnimated_DoesNotInsertRowsWhenOldCountIsGreaterThanNewCount() {
        // Given
        let tableViewSpy = TableViewSpy()
        sut.tableView = tableViewSpy
        
        // When
        sut.updateTableViewAnimated(oldCount: 5, newCount: 2)
        
        // Then
        XCTAssertFalse(tableViewSpy.insertRowsCalled, "insertRows should not be called when oldCount > newCount")
        XCTAssertEqual(tableViewSpy.insertedIndexPaths.count, 0, "No rows should be inserted when oldCount > newCount")
    }
    
    func testUpdateTableViewAnimated_DoesNotInsertRowsWhenOldCountEqualsNewCount() {
        // Given
        let tableViewSpy = TableViewSpy()
        sut.tableView = tableViewSpy
        
        // When
        sut.updateTableViewAnimated(oldCount: 5, newCount: 5)
        
        // Then
        XCTAssertFalse(tableViewSpy.insertRowsCalled, "insertRows should not be called when oldCount == newCount")
        XCTAssertEqual(tableViewSpy.insertedIndexPaths.count, 0, "No rows should be inserted when oldCount == newCount")
    }
    
    func testShowLikeErrorAlert_PresentsAlert() {
        // Given
        let window = UIWindow()
        window.rootViewController = sut
        window.makeKeyAndVisible()
        
        // When
        sut.showLikeErrorAlert()
        
        // Then
        XCTAssertTrue(sut.presentedViewController is UIAlertController, "UIAlertController should be presented")
    }
}

class TableViewSpy: UITableView {
    var insertRowsCalled = false
    var insertedIndexPaths: [IndexPath] = []
    
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        insertRowsCalled = true
        insertedIndexPaths = indexPaths
    }
}

class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var updateTableViewAnimatedCalled = false
    var showLikeErrorAlertCalled = false
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        updateTableViewAnimatedCalled = true
    }
    
    func showLikeErrorAlert() {
        showLikeErrorAlertCalled = true
    }
}
