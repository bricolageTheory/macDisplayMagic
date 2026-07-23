import XCTest
@testable import macDisplayMagic

final class DisplayClassifierTests: XCTestCase {
    func testRulesStoreHierarchyFallback() {
        let store = RulesStore.shared
        // Evaluate built-in Retina screen default
        let builtinAction = store.evaluateRule(appBundleID: "com.apple.Preview", displayCategory: .builtIn)
        XCTAssertEqual(builtinAction, ZoomAction.reset100)

        // Evaluate 4K screen global default rule
        let uhd4KAction = store.evaluateRule(appBundleID: "com.apple.Safari", displayCategory: .uhd4K)
        XCTAssertEqual(uhd4KAction, ZoomAction.zoomIn(steps: 2))
    }

    func testZoomActionDescription() {
        let actionReset = ZoomAction.reset100
        let actionZoomIn = ZoomAction.zoomIn(steps: 3)
        XCTAssertTrue(actionReset.description.contains("100%"))
        XCTAssertTrue(actionZoomIn.description.contains("+3"))
    }

    func testSafariDomainExclusionWithTitleFallback() {
        AppSettings.shared.enableNoZoomingDomain = true
        AppSettings.shared.noZoomDomains = ["youtube.com", "www.netflix.com", "https://disneyplus.com"]

        let safariBundleID = "com.apple.Safari"
        let dummyPID: pid_t = 9999

        // Test YouTube video title in Safari
        let (youtubeExcluded, youtubeDomain) = TabZoomTracker.shared.checkDomainExclusion(
            bundleID: safariBundleID,
            pid: dummyPID,
            windowTitle: "Lo-Fi Beats - YouTube"
        )
        XCTAssertTrue(youtubeExcluded)
        XCTAssertEqual(youtubeDomain, "youtube.com")

        // Test Netflix title in Safari with www. prefix in exclusion list
        let (netflixExcluded, netflixDomain) = TabZoomTracker.shared.checkDomainExclusion(
            bundleID: safariBundleID,
            pid: dummyPID,
            windowTitle: "Stranger Things | Netflix"
        )
        XCTAssertTrue(netflixExcluded)
        XCTAssertEqual(netflixDomain, "www.netflix.com")

        // Test non-excluded domain
        let (otherExcluded, _) = TabZoomTracker.shared.checkDomainExclusion(
            bundleID: safariBundleID,
            pid: dummyPID,
            windowTitle: "Apple - Official Site"
        )
        XCTAssertFalse(otherExcluded)
    }
}
