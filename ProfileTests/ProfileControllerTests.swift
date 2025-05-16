import XCTest
@testable import ImageFeed
import Foundation

final class ProfileViewControllerTests: XCTestCase {
    var viewControllerSpy: ProfileViewControllerSpy!
    var presenter: ProfilePresenter!
    var profileService: ProfileService!
    var profileImageService: ProfileImageService!
    var profileLogoutService: ProfileLogoutService!
    
    override func setUp() {
        super.setUp()
        // Инициализация шпиона для ProfileViewController
        viewControllerSpy = ProfileViewControllerSpy()
        
        // Инициализация сервисов и презентера
        profileService = ProfileService.shared
        profileImageService = ProfileImageService.shared
        profileLogoutService = ProfileLogoutService.shared
        
        // Создание презентера и привязка шпиона как view
        presenter = ProfilePresenter(
            profileService: profileService,
            profileImageService: profileImageService,
            profileLogoutService: profileLogoutService
        )
        presenter.view = viewControllerSpy
    }
    
    override func tearDown() {
        viewControllerSpy = nil
        presenter = nil
        profileService = nil
        profileImageService = nil
        profileLogoutService = nil
        super.tearDown()
    }
    
    func testDisplayProfile() {
        // Arrange
        let profile = Profile(profileResult: ProfileResult(
            username: "testuser",
            name: "Test User",
            firstName: "Test",
            lastName: "User",
            bio: "This is a test bio"
        ))
        profileService.profile = profile
        
        // Act
        presenter.updateProfile()
        
        // Assert
        XCTAssertTrue(viewControllerSpy.isDisplayProfileCalled)
        XCTAssertEqual(viewControllerSpy.displayedName, "Test User")
        XCTAssertEqual(viewControllerSpy.displayedLogin, "@testuser")
        XCTAssertEqual(viewControllerSpy.displayedBio, "This is a test bio")
    }
    
    func testDisplayAvatar() {
        // Arrange
        let avatarURLString = "https://example.com/avatar.png"
        profileImageService.avatarURL = avatarURLString
        
        // Act
        presenter.updateAvatar()
        
        // Assert
        XCTAssertTrue(viewControllerSpy.isDisplayAvatarCalled)
        XCTAssertEqual(viewControllerSpy.displayedAvatarURL?.absoluteString, avatarURLString)
    }
    
    func testNavigateToSplashScreen() {
        // Act
        presenter.didConfirmLogout()
        
        // Assert
        XCTAssertTrue(viewControllerSpy.isNavigateToSplashScreenCalled)
    }
    
    func testShowLogoutAlert() {
        // Act
        presenter.didTapLogout()
        
        // Assert
        XCTAssertTrue(viewControllerSpy.isShowLogoutAlertCalled)
    }
}

final class ProfileViewControllerSpy: ProfileViewProtocol {
    // MARK: - UI Elements
    var isDisplayProfileCalled = false
    var displayedName: String?
    var displayedLogin: String?
    var displayedBio: String?
    
    var isDisplayAvatarCalled = false
    var displayedAvatarURL: URL?
    
    var isNavigateToSplashScreenCalled = false
    var isShowLogoutAlertCalled = false
    
    // MARK: - Override Methods
    func displayProfile(name: String, login: String, bio: String?) {
        isDisplayProfileCalled = true
        displayedName = name
        displayedLogin = login
        displayedBio = bio
    }
    
    func displayAvatar(url: URL?) {
        isDisplayAvatarCalled = true
        displayedAvatarURL = url
    }
    
    func navigateToSplashScreen() {
        isNavigateToSplashScreenCalled = true
    }
    
    func showLogoutAlert() {
        isShowLogoutAlertCalled = true
    }
}
