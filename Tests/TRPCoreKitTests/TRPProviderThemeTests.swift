import XCTest
@testable import TRPCoreKit

/// Colours a provider has always shown must not change when another provider's theme does.
final class TRPProviderThemeTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        super.tearDown()
    }

    func testPinkForegroundKeepsEachProvidersColour() {
        TRPCoreKit.shared.provider = .civitatis
        XCTAssertEqual(ColorSet.fgPink.uiColor, UIColor(red: 194, green: 4, blue: 75))

        TRPCoreKit.shared.provider = .getYourGuide
        XCTAssertEqual(ColorSet.fgPink.uiColor, UIColor(red: 234, green: 5, blue: 88))

        TRPCoreKit.shared.provider = .nexus
        XCTAssertEqual(ColorSet.fgPink.uiColor, UIColor(red: 255, green: 98, blue: 29))
    }
}
