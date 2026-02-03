@testable import OfflineCards
import XCTest

final class AppDelegateTests: XCTestCase {
    var appDelegate: AppDelegate!

    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        // Reset to default state
        AppDelegate.orientationLock = .portrait
    }

    override func tearDown() {
        // Reset to default state after tests
        AppDelegate.orientationLock = .portrait
        appDelegate = nil
        super.tearDown()
    }

    func testDefaultOrientationIsPortrait() throws {
        // Given: Fresh app delegate
        let delegate = AppDelegate()

        // When: Checking default orientation
        let result = delegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        )

        // Then: Should be portrait only
        XCTAssertEqual(result, .portrait)
    }

    func testOrientationLockPortrait() throws {
        // Given: Orientation set to portrait
        AppDelegate.orientationLock = .portrait

        // When: Checking supported orientations
        let result = appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        )

        // Then: Should return portrait
        XCTAssertEqual(result, .portrait)
    }

    func testOrientationLockLandscape() throws {
        // Given: Orientation set to landscape
        AppDelegate.orientationLock = .landscape

        // When: Checking supported orientations
        let result = appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        )

        // Then: Should return landscape
        XCTAssertEqual(result, .landscape)
    }

    func testOrientationLockAll() throws {
        // Given: Orientation set to all
        AppDelegate.orientationLock = .all

        // When: Checking supported orientations
        let result = appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        )

        // Then: Should return all orientations
        XCTAssertEqual(result, .all)
    }

    func testOrientationLockCanBeChanged() throws {
        // Given: Initial portrait orientation
        AppDelegate.orientationLock = .portrait
        XCTAssertEqual(appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        ), .portrait)

        // When: Changing to landscape
        AppDelegate.orientationLock = .landscape

        // Then: Should return landscape
        XCTAssertEqual(appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        ), .landscape)

        // When: Changing back to portrait
        AppDelegate.orientationLock = .portrait

        // Then: Should return portrait
        XCTAssertEqual(appDelegate.application(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        ), .portrait)
    }
}
