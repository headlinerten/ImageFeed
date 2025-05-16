import XCTest
@testable import ImageFeed

class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("UITestsMode")
        app.launch()
    }
    
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let existsPredicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        switch result {
        case .completed:
            return true // Элемент найден
        default:
            XCTFail("Элемент \(element) не найден за \(timeout) секунд")
            return false // Элемент не найден
        }
    }
    
    func pasteText(for app: XCUIApplication) {
        let pasteMenuItems = [
            app.menuItems["Paste"],
            app.menuItems["Вставить"]
        ]
        
        guard let pasteMenuItem = pasteMenuItems.first(where: { $0.exists }) else {
            XCTFail("Не найден пункт Paste / Вставить")
            return
        }
        
        // Проверяем результат waitForElement
        if waitForElement(pasteMenuItem, timeout: 2) {
            pasteMenuItem.tap()
        } else {
            XCTFail("Не удалось дождаться появления пункта Paste / Вставить")
        }
    }
    
    func testAuth() throws {
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(waitForElement(authButton, timeout: 15), "Кнопка Authenticate не найдена")
        authButton.tap()
        
        let webView = app.webViews.firstMatch
        XCTAssertTrue(waitForElement(webView, timeout: 15), "Веб-вью не найдено")
        
        UIPasteboard.general.string = "headlinerten@gmail.com"
        let loginTextField = webView.textFields.firstMatch
        XCTAssertTrue(waitForElement(loginTextField, timeout: 10), "Поле для ввода логина не найдено")
        loginTextField.tap()
        loginTextField.doubleTap()
        pasteText(for: app)
        
        webView.swipeUp()
        
        UIPasteboard.general.string = "Elista2191"
        let passwordTextField = webView.secureTextFields.firstMatch
        XCTAssertTrue(waitForElement(passwordTextField, timeout: 10), "Поле для ввода пароля не найдено")
        passwordTextField.tap()
        passwordTextField.doubleTap()
        pasteText(for: app)
        
        webView.swipeUp()
        
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(waitForElement(loginButton, timeout: 10), "Кнопка Login не найдена")
        loginButton.tap()
        
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(waitForElement(tablesQuery, timeout: 15), "Лента не загрузилась")
    }
    
    func testFeed() throws {
        // Ожидаем появления таблицы
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(waitForElement(tablesQuery, timeout: 15), "Таблица не найдена")
        
        // Ожидаем появления первой ячейки
        let firstCell = tablesQuery.cells.firstMatch
        XCTAssertTrue(waitForElement(firstCell, timeout: 10), "Первая ячейка не найдена")
        
        // Прокручиваем таблицу вверх
        tablesQuery.swipeUp()
        
        // Проверяем, что кнопка лайка существует
        let likeButton = firstCell.buttons["likeButton"]
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка не найдена")
        
        // Нажимаем на кнопку лайка
        likeButton.tap()
        
        // Проверяем, что кнопка лайка всё ещё существует после первого нажатия
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка исчезла после первого нажатия")
        
        // Нажимаем на кнопку лайка ещё раз
        likeButton.tap()
        
        // Проверяем, что кнопка лайка всё ещё существует после второго нажатия
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка исчезла после второго нажатия")
        
        // Нажимаем на первую ячейку
        firstCell.tap()
        
        // Ожидаем появления изображения
        let image = app.scrollViews.images.firstMatch
        XCTAssertTrue(waitForElement(image, timeout: 5), "Изображение не найдено")
        
        // Увеличиваем масштаб изображения
        image.pinch(withScale: 3, velocity: 1)
        
        // Уменьшаем масштаб изображения
        image.pinch(withScale: 0.5, velocity: -1)
        
        // Ожидаем появления кнопки "Назад"
        let backButton = app.buttons["backButton"]
        XCTAssertTrue(waitForElement(backButton, timeout: 5), "Кнопка 'Назад' не найдена")
        
        // Нажимаем на кнопку "Назад"
        backButton.tap()
    }
    
    func testProfile() throws {
        // Ожидаем появления таблицы
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(waitForElement(tablesQuery, timeout: 15), "Таблица не найдена")
        
        // Ожидаем появления первой ячейки
        let firstCell = tablesQuery.cells.firstMatch
        XCTAssertTrue(waitForElement(firstCell, timeout: 10), "Первая ячейка не найдена")
        
        // Переходим на вкладку профиля
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(waitForElement(profileTab, timeout: 5), "Вкладка профиля не найдена")
        profileTab.tap()
        
        // Проверяем наличие и текст метки имени
        let nameLabel = app.staticTexts["Tenzin Sangadzhiev"]
        XCTAssertTrue(waitForElement(nameLabel, timeout: 10), "Метка имени не найдена")
        XCTAssertEqual(nameLabel.label, "Tenzin Sangadzhiev", "Текст метки имени не соответствует ожидаемому")
        
        // Проверяем наличие и текст метки логина
        let loginLabel = app.staticTexts["@headlinerten"]
        XCTAssertTrue(waitForElement(loginLabel, timeout: 10), "Метка логина не найдена")
        XCTAssertEqual(loginLabel.label, "@headlinerten", "Текст метки логина не соответствует ожидаемому")
        
        // Проверяем наличие и текст метки описания
        let descriptionLabel = app.staticTexts["Нет описания"]
        XCTAssertTrue(waitForElement(descriptionLabel, timeout: 10), "Метка описания не найдена")
        XCTAssertEqual(descriptionLabel.label, "Нет описания", "Текст метки описания не соответствует ожидаемому")
        
        // Проверяем наличие кнопки выхода
        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(waitForElement(logoutButton, timeout: 10), "Кнопка выхода не найдена")
        logoutButton.tap()
        
        // Проверяем появление алерта выхода
        let logoutAlert = app.alerts["Пока, пока!"]
        XCTAssertTrue(waitForElement(logoutAlert, timeout: 10), "Алерт выхода не появился")
        
        // Проверяем наличие кнопки "Да" в алерте
        let yesButton = logoutAlert.buttons["Да"]
        XCTAssertTrue(waitForElement(yesButton, timeout: 10), "Кнопка 'Да' в алерте не найдена")
        yesButton.tap()
        
        // Проверяем переход на экран аутентификации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(waitForElement(authButton, timeout: 15), "Кнопка аутентификации не найдена")
    }
}
