import XCTest
@testable import macDisplayMagic

final class DisplayClassifierTests: XCTestCase {
    func testRulesStoreHierarchyFallback() {
        let store = RulesStore.shared
        // Evaluate built-in Retina screen default
        let builtinAction = store.evaluateRule(appBundleID: "com.apple.Preview", displayCategory: .builtIn, displayIDString: "100")
        XCTAssertEqual(builtinAction, .reset100)

        // Evaluate 4K screen global default rule
        let uhd4KAction = store.evaluateRule(appBundleID: "com.apple.Safari", displayCategory: .uhd4K, displayIDString: "200")
        XCTAssertEqual(uhd4KAction, .zoomIn(steps: 2))
    }

    func testZoomActionDescription() {
        let actionReset = ZoomAction.reset100
        let actionZoomIn = ZoomAction.zoomIn(steps: 3)
        XCTAssertTrue(actionReset.description.contains("100%"))
        XCTAssertTrue(actionZoomIn.description.contains("+3"))
    }
}
