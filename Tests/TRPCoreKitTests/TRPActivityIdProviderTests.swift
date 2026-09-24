import XCTest
@testable import TRPCoreKit

/// The activity id the tour-api expects is `{prefix}{productId}_{providerId}[_{cityId}]`, with the
/// prefix and provider id of the active provider. These pin building and taking it apart per provider.
final class TRPActivityIdProviderTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        super.tearDown()
    }

    private let expectations: [(provider: TripianProvider, prefix: String, id: Int)] = [
        (.civitatis, "C_", 15),
        (.nexus, "J_", 7),
        (.getYourGuide, "G_", 4)
    ]

    // MARK: - Building

    func testEachProviderWrapsAPlainIdWithItsPrefixAndProviderId() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual(TRPActivityIdFormat.make("12345"), "\(expected.prefix)12345_\(expected.id)", "\(expected.provider)")
        }
    }

    func testEachProviderAppendsTheCityIdWhenKnown() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual(TRPActivityIdFormat.make("12345", cityId: 109), "\(expected.prefix)12345_\(expected.id)_109", "\(expected.provider)")
        }
    }

    func testAnExplicitProviderIdOverridesTheActiveProvidersId() {
        TRPCoreKit.shared.provider = .nexus

        XCTAssertEqual(TRPActivityIdFormat.make("12345", providerId: 99), "J_12345_99")
    }

    func testAnAlreadyWrappedIdIsReducedToItsProductIdBeforeWrappingAgain() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider
            let wrapped = "\(expected.prefix)777_\(expected.id)_3"

            XCTAssertEqual(TRPActivityIdFormat.make(wrapped, cityId: 5), "\(expected.prefix)777_\(expected.id)_5", "\(expected.provider)")
        }
    }

    func testNexusProductIdWithItsTypeSuffixSurvivesWrapping() {
        TRPCoreKit.shared.provider = .nexus

        let id = TRPActivityIdFormat.make("9148\u{AC}TKT", cityId: 55)

        XCTAssertEqual(id, "J_9148\u{AC}TKT_7_55")
        XCTAssertEqual(id.cleanedAsActivityId(), "9148\u{AC}TKT")
        XCTAssertEqual(id.trp_parsedProviderId(), 7)
    }

    // MARK: - Normalizing

    func testNormalizedKeepsAnIdCarryingTheActiveProvidersPrefixUntouched() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider
            let wrapped = "\(expected.prefix)777_\(expected.id)_3"

            XCTAssertEqual(TRPActivityIdFormat.normalized(wrapped, cityId: 9), wrapped, "\(expected.provider)")
        }
    }

    func testNormalizedWrapsAPlainId() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual(TRPActivityIdFormat.normalized("777", cityId: 9), "\(expected.prefix)777_\(expected.id)_9", "\(expected.provider)")
        }
    }

    // MARK: - Taking apart

    func testCleanedIdIsTheProductIdForEachProvider() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual("\(expected.prefix)15423_\(expected.id)".cleanedAsActivityId(), "15423", "\(expected.provider)")
            XCTAssertEqual("\(expected.prefix)15423_\(expected.id)_109".cleanedAsActivityId(), "15423", "\(expected.provider)")
        }
    }

    func testCleanedIdLeavesAPlainIdAlone() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual("15423".cleanedAsActivityId(), "15423", "\(expected.provider)")
            XCTAssertEqual("BOOKING_12345".cleanedAsActivityId(), "BOOKING_12345", "\(expected.provider)")
        }
    }

    func testCleanedIdLeavesAnotherProvidersIdAlone() {
        TRPCoreKit.shared.provider = .nexus

        XCTAssertEqual("C_15423_15".cleanedAsActivityId(), "C_15423_15")
        XCTAssertEqual("G_15423_4".cleanedAsActivityId(), "G_15423_4")
    }

    func testParsedProviderIdIsReadFromTheSecondPart() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertEqual("\(expected.prefix)15423_\(expected.id)".trp_parsedProviderId(), expected.id, "\(expected.provider)")
            XCTAssertEqual("\(expected.prefix)15423_\(expected.id)_109".trp_parsedProviderId(), expected.id, "\(expected.provider)")
        }
    }

    func testParsedProviderIdIsNilWithoutAProviderPart() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider

            XCTAssertNil("15423".trp_parsedProviderId(), "\(expected.provider)")
            XCTAssertNil("\(expected.prefix)15423".trp_parsedProviderId(), "\(expected.provider)")
            XCTAssertNil("\(expected.prefix)15423_abc".trp_parsedProviderId(), "\(expected.provider)")
        }
    }

    /// A product id that itself contains `_` cannot be told apart from the provider part, so it
    /// does not survive a round trip through the wrapped form.
    func testProductIdWithAnUnderscoreDoesNotRoundTrip() {
        for expected in expectations {
            TRPCoreKit.shared.provider = expected.provider
            let wrapped = TRPActivityIdFormat.make("ABC_DEF")

            XCTAssertEqual(wrapped, "\(expected.prefix)ABC_DEF_\(expected.id)", "\(expected.provider)")
            XCTExpectFailure("an underscore inside the product id is read as the provider separator") {
                XCTAssertEqual(wrapped.cleanedAsActivityId(), "ABC_DEF", "\(expected.provider)")
                XCTAssertEqual(wrapped.trp_parsedProviderId(), expected.id, "\(expected.provider)")
            }
        }
    }

    // MARK: - Detail id

    func testNexusSwapsTheTourApiIdIntoTheProductLookupForm() {
        XCTAssertEqual(TripianProvider.nexus.activityDetailId(fromRaw: "9148\u{AC}TKT"), "TKT|9148")
    }

    func testNexusDetailIdIsIdempotent() {
        XCTAssertEqual(TripianProvider.nexus.activityDetailId(fromRaw: "TKT|9148"), "TKT|9148")
        XCTAssertEqual(TripianProvider.nexus.activityDetailId(fromRaw: "9148"), "9148")
    }

    func testNexusLeavesIdsThatAreNotDigitsThenTypeUnchanged() {
        for raw in ["ABC\u{AC}TKT", "9148\u{AC}", "\u{AC}TKT", "1\u{AC}2\u{AC}3", "91a8\u{AC}TKT"] {
            XCTAssertEqual(TripianProvider.nexus.activityDetailId(fromRaw: raw), raw, raw)
        }
    }

    func testCivitatisAndGetYourGuideUseTheRawIdAsTheDetailId() {
        for provider in [TripianProvider.civitatis, .getYourGuide] {
            XCTAssertEqual(provider.activityDetailId(fromRaw: "9148\u{AC}TKT"), "9148\u{AC}TKT", "\(provider)")
            XCTAssertEqual(provider.activityDetailId(fromRaw: "15423"), "15423", "\(provider)")
        }
    }

    // MARK: - Provider values

    func testProviderIdsAndPrefixes() {
        for expected in expectations {
            XCTAssertEqual(expected.provider.id, expected.id)
            XCTAssertEqual(expected.provider.activityIdPrefix, expected.prefix)
        }
    }

    func testOnlyNexusUsesTheFlatTimeline() {
        XCTAssertTrue(TripianProvider.nexus.usesFlatTimeline)
        XCTAssertFalse(TripianProvider.civitatis.usesFlatTimeline)
        XCTAssertFalse(TripianProvider.getYourGuide.usesFlatTimeline)
    }

    func testOnlyCivitatisShowsActivityCategories() {
        XCTAssertTrue(TripianProvider.civitatis.showsActivityCategories)
        XCTAssertFalse(TripianProvider.nexus.showsActivityCategories)
        XCTAssertFalse(TripianProvider.getYourGuide.showsActivityCategories)
    }

    func testOnlyCivitatisResolvesHostCityIdsAgain() {
        XCTAssertFalse(TripianProvider.civitatis.keepsHostCityIds)
        XCTAssertTrue(TripianProvider.nexus.keepsHostCityIds)
        XCTAssertTrue(TripianProvider.getYourGuide.keepsHostCityIds)
    }
}
