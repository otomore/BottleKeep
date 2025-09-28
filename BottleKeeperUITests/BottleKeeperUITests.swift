import XCTest

final class BottleKeeperUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func testTabBarNavigation() throws {
        // ボトル一覧タブ
        let bottleListTab = app.tabBars.buttons["ボトル"]
        XCTAssertTrue(bottleListTab.exists)
        bottleListTab.tap()

        // ウィッシュリストタブ
        let wishlistTab = app.tabBars.buttons["ウィッシュリスト"]
        XCTAssertTrue(wishlistTab.exists)
        wishlistTab.tap()

        // 統計タブ
        let statisticsTab = app.tabBars.buttons["統計"]
        XCTAssertTrue(statisticsTab.exists)
        statisticsTab.tap()

        // 設定タブ
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.exists)
        settingsTab.tap()
    }

    // MARK: - Bottle List Tests

    func testBottleListEmptyState() throws {
        let bottleListTab = app.tabBars.buttons["ボトル"]
        bottleListTab.tap()

        // 空の状態のUI要素を確認
        XCTAssertTrue(app.staticTexts["ボトルが登録されていません"].exists)
        XCTAssertTrue(app.buttons["最初のボトルを追加"].exists)
    }

    func testAddBottleFlow() throws {
        let bottleListTab = app.tabBars.buttons["ボトル"]
        bottleListTab.tap()

        // 追加ボタンをタップ
        let addButton = app.navigationBars.buttons["追加"]
        if addButton.exists {
            addButton.tap()
        } else {
            // 空の状態から追加
            let firstAddButton = app.buttons["最初のボトルを追加"]
            firstAddButton.tap()
        }

        // フォーム画面のUI要素を確認
        XCTAssertTrue(app.navigationBars["ボトル追加"].exists)
        XCTAssertTrue(app.textFields["ボトル名"].exists)
        XCTAssertTrue(app.textFields["蒸留所名"].exists)

        // フォームに入力
        let nameField = app.textFields["ボトル名"]
        nameField.tap()
        nameField.typeText("テストボトル")

        let distilleryField = app.textFields["蒸留所名"]
        distilleryField.tap()
        distilleryField.typeText("テスト蒸留所")

        // 保存ボタンをタップ
        let saveButton = app.navigationBars.buttons["保存"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        // ボトル一覧に戻ることを確認
        XCTAssertTrue(app.navigationBars["ボトル一覧"].exists)
    }

    func testBottleSearch() throws {
        let bottleListTab = app.tabBars.buttons["ボトル"]
        bottleListTab.tap()

        // 検索フィールドが存在する場合のテスト
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("テスト")

            // 検索結果の確認（実際のデータによる）
            XCTAssertTrue(app.navigationBars["ボトル一覧"].exists)
        }
    }

    // MARK: - Wishlist Tests

    func testWishlistEmptyState() throws {
        let wishlistTab = app.tabBars.buttons["ウィッシュリスト"]
        wishlistTab.tap()

        // 空の状態のUI要素を確認
        XCTAssertTrue(app.staticTexts["ウィッシュリストが空です"].exists)
        XCTAssertTrue(app.buttons["最初のアイテムを追加"].exists)
    }

    func testAddWishlistItemFlow() throws {
        let wishlistTab = app.tabBars.buttons["ウィッシュリスト"]
        wishlistTab.tap()

        // 追加ボタンをタップ
        let addButton = app.navigationBars.buttons["追加"]
        if addButton.exists {
            addButton.tap()
        } else {
            // 空の状態から追加
            let firstAddButton = app.buttons["最初のアイテムを追加"]
            firstAddButton.tap()
        }

        // フォーム画面のUI要素を確認
        XCTAssertTrue(app.navigationBars["ウィッシュリストに追加"].exists)
        XCTAssertTrue(app.textFields["ボトル名"].exists)
        XCTAssertTrue(app.textFields["蒸留所"].exists)

        // フォームに入力
        let nameField = app.textFields["ボトル名"]
        nameField.tap()
        nameField.typeText("欲しいボトル")

        let distilleryField = app.textFields["蒸留所"]
        distilleryField.tap()
        distilleryField.typeText("欲しい蒸留所")

        // 優先度を選択
        let prioritySegmentedControl = app.segmentedControls["優先度"]
        if prioritySegmentedControl.exists {
            prioritySegmentedControl.buttons["高"].tap()
        }

        // 保存ボタンをタップ
        let saveButton = app.navigationBars.buttons["保存"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        // ウィッシュリスト画面に戻ることを確認
        XCTAssertTrue(app.navigationBars["ウィッシュリスト"].exists)
    }

    // MARK: - Statistics Tests

    func testStatisticsView() throws {
        let statisticsTab = app.tabBars.buttons["統計"]
        statisticsTab.tap()

        // 統計画面のUI要素を確認
        XCTAssertTrue(app.navigationBars["統計"].exists)

        // データがある場合の統計カードの確認
        if app.staticTexts["概要"].exists {
            XCTAssertTrue(app.staticTexts["総ボトル数"].exists)
            XCTAssertTrue(app.staticTexts["開栓済み"].exists)
            XCTAssertTrue(app.staticTexts["未開栓"].exists)
            XCTAssertTrue(app.staticTexts["総価値"].exists)
        }
    }

    func testStatisticsRefresh() throws {
        let statisticsTab = app.tabBars.buttons["統計"]
        statisticsTab.tap()

        // 引っ張って更新のテスト
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
        }
    }

    // MARK: - Settings Tests

    func testSettingsView() throws {
        let settingsTab = app.tabBars.buttons["設定"]
        settingsTab.tap()

        // 設定画面のUI要素を確認
        XCTAssertTrue(app.navigationBars["設定"].exists)
    }

    // MARK: - Accessibility Tests

    func testAccessibility() throws {
        // メインタブの accessibility を確認
        XCTAssertTrue(app.tabBars.buttons["ボトル"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["ウィッシュリスト"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["統計"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["設定"].isHittable)
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}