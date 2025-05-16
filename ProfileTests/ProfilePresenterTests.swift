import XCTest
@testable import ImageFeed

final class ProfilePresenterTests: XCTestCase {
    var presenter: ProfilePresenter!
    var viewSpy: ProfileViewControllerSpy!
    var profileService: ProfileService!
    var profileImageService: ProfileImageService!
    var profileLogoutService: ProfileLogoutService!
    
    override func setUp() {
        super.setUp()
        viewSpy = ProfileViewControllerSpy()
        profileService = ProfileService.shared
        profileImageService = ProfileImageService.shared
        profileLogoutService = ProfileLogoutService.shared
        presenter = ProfilePresenter(
            profileService: profileService,
            profileImageService: profileImageService,
            profileLogoutService: profileLogoutService
        )
        presenter.view = viewSpy
    }
    
    override func tearDown() {
        presenter = nil
        viewSpy = nil
        profileService = nil
        profileImageService = nil
        profileLogoutService = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        // Act
        presenter.viewDidLoad()
        
        // Assert
        XCTAssertTrue(viewSpy.displayedName != nil)
        XCTAssertTrue(viewSpy.displayedLogin != nil)
        XCTAssertTrue(viewSpy.displayedBio != nil)
        XCTAssertTrue(viewSpy.displayedAvatarURL != nil)
    }
    
    func testDidTapLogout() {
        // Act
        presenter.didTapLogout()
        
        // Assert
        XCTAssertTrue(viewSpy.isShowLogoutAlertCalled)
    }
    
    func testDidConfirmLogout() {
        // Act
        presenter.didConfirmLogout()
        
        // Assert
        XCTAssertTrue(viewSpy.isNavigateToSplashScreenCalled)
    }
    
    func testUpdateProfile() {
        // Arrange
        let profileResult = ProfileResult(
            username: "testuser",
            name: "name",
            firstName: "Test",
            lastName: "lastname",
            bio: "Bio"
        )
        let profile = Profile(profileResult: profileResult)
        profileService.profile = profile
        
        // Act
        presenter.updateProfile()
        
        // Assert
        XCTAssertEqual(viewSpy.displayedName, "Test lastname") // Ожидаемое значение
        XCTAssertEqual(viewSpy.displayedLogin, "@testuser")    // Ожидаемое значение
        XCTAssertEqual(viewSpy.displayedBio, "Bio")           // Ожидаемое значение
    }
    
    func testUpdateAvatar() {
        // Arrange
        let avatarURLString = "https://example.com/avatar.png"
        profileImageService.avatarURL = avatarURLString
        
        // Act
        presenter.updateAvatar()
        
        // Assert
        XCTAssertEqual(viewSpy.displayedAvatarURL?.absoluteString, avatarURLString)
    }
}
final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewProtocol?
    var isViewDidLoadCalled = false
    var isDidTapLogoutCalled = false
    var isDidConfirmLogoutCalled = false
    var isUpdateProfileCalled = false
    var isUpdateAvatarCalled = false
    var avatarURL: URL?
    var isNavigateToSplashScreenCalled = false
    var isShowLogoutAlertCalled = false
    
    func navigateToSplashScreen() {
        isNavigateToSplashScreenCalled = true
    }
    func viewDidLoad() {
        isViewDidLoadCalled = true
    }
    
    func didTapLogout() {
        isDidTapLogoutCalled = true
    }
    func showLogoutAlert() {
        isShowLogoutAlertCalled = true
    }
    
    func didConfirmLogout() {
        isDidConfirmLogoutCalled = true
    }
    
    func updateProfile() {
        isUpdateProfileCalled = true
    }
    
    func updateAvatar() {
        isUpdateAvatarCalled = true
    }
}

