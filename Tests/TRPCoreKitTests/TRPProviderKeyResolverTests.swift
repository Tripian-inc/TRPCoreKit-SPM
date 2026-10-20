import XCTest
import MapboxMaps
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins the resolution order for host-supplied Mapbox/Places keys against the Info.plist fallback,
/// and that `setProviderKeys`/`initialize` forward those keys without touching the host's unrelated state.
final class TRPProviderKeyResolverTests: XCTestCase {

    private func makeResolver(plist: @escaping (TRPApiKeys) -> String? = { _ in nil }) -> TRPProviderKeyResolver {
        return TRPProviderKeyResolver(plistKey: plist)
    }

    // MARK: - Mapbox token resolution

    func testHostMapboxTokenWinsOverPlist() {
        let resolver = makeResolver(plist: { _ in "plist-token" })
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "host-token")

        XCTAssertEqual(resolver.mapboxAccessToken(), "host-token")
    }

    func testEmptyHostMapboxTokenFallsBackToPlist() {
        let resolver = makeResolver(plist: { _ in "plist-token" })
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "")

        XCTAssertEqual(resolver.mapboxAccessToken(), "plist-token")
    }

    func testNilHostMapboxTokenReturnsPlistValue() {
        let resolver = makeResolver(plist: { _ in "plist-token" })

        XCTAssertEqual(resolver.mapboxAccessToken(), "plist-token")
    }

    func testNilHostAndNilPlistMapboxTokenReturnsNil() {
        let resolver = makeResolver(plist: { _ in nil })

        XCTAssertNil(resolver.mapboxAccessToken())
    }

    // MARK: - Google Places key resolution

    func testHostPlacesKeyWinsOverPlist() {
        let resolver = makeResolver(plist: { _ in "plist-places" })
        resolver.hostKeys = TRPProviderKeys(googlePlacesApiKey: "host-places")

        XCTAssertEqual(resolver.googlePlacesApiKey(), "host-places")
    }

    func testEmptyHostPlacesKeyFallsBackToPlist() {
        let resolver = makeResolver(plist: { _ in "plist-places" })
        resolver.hostKeys = TRPProviderKeys(googlePlacesApiKey: "")

        XCTAssertEqual(resolver.googlePlacesApiKey(), "plist-places")
    }

    func testNilHostPlacesKeyReturnsPlistValue() {
        let resolver = makeResolver(plist: { _ in "plist-places" })

        XCTAssertEqual(resolver.googlePlacesApiKey(), "plist-places")
    }

    func testNilHostAndNilPlistPlacesKeyReturnsNil() {
        let resolver = makeResolver(plist: { _ in nil })

        XCTAssertNil(resolver.googlePlacesApiKey())
    }

    // MARK: - hasHostValue

    func testHasHostValueIsTrueOnlyWhenTheHostSuppliedANonEmptyValue() {
        let resolver = makeResolver()
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "host-token", googlePlacesApiKey: "")

        XCTAssertTrue(resolver.hasHostValue(for: .mglMapboxAccessToken))
        XCTAssertFalse(resolver.hasHostValue(for: .trpGooglePlace))
        XCTAssertFalse(resolver.hasHostValue(for: .trpUberClient))
    }

    // MARK: - setProviderKeys / sink

    func testSetProviderKeysCallsTheSinkOnceWithTheResolvedMapboxToken() {
        let resolver = makeResolver(plist: { _ in nil })
        var received: [String] = []
        let coreKit = TRPCoreKit(keyResolver: resolver, mapboxTokenSink: { received.append($0) })

        coreKit.setProviderKeys(TRPProviderKeys(mapboxAccessToken: "host-token"))

        XCTAssertEqual(received, ["host-token"])
    }

    func testSetProviderKeysResolvesThePlistTokenWhenTheHostSuppliesNone() {
        let resolver = makeResolver(plist: { $0 == .mglMapboxAccessToken ? "plist-token" : nil })
        var received: [String] = []
        let coreKit = TRPCoreKit(keyResolver: resolver, mapboxTokenSink: { received.append($0) })

        coreKit.setProviderKeys(TRPProviderKeys())

        XCTAssertEqual(received, ["plist-token"])
    }

    func testSetProviderKeysSkipsTheSinkWhenNothingResolves() {
        let resolver = makeResolver(plist: { _ in nil })
        var received: [String] = []
        let coreKit = TRPCoreKit(keyResolver: resolver, mapboxTokenSink: { received.append($0) })

        coreKit.setProviderKeys(TRPProviderKeys())

        XCTAssertTrue(received.isEmpty)
    }

    // MARK: - initialize forwarding

    func testInitializeForwardsBothKeysToTheSharedResolver() {
        let originalHostKeys = TRPProviderKeyResolver.shared.hostKeys
        let originalMapboxToken = MapboxOptions.accessToken
        defer {
            TRPProviderKeyResolver.shared.hostKeys = originalHostKeys
            MapboxOptions.accessToken = originalMapboxToken
        }

        TRPCoreKit.initialize(baseUrl: "https://example.com",
                              basePath: "v1",
                              apiKey: "test-api-key",
                              mapboxAccessToken: "host-token",
                              googlePlacesApiKey: "host-places")

        XCTAssertEqual(TRPProviderKeyResolver.shared.hostKeys.mapboxAccessToken, "host-token")
        XCTAssertEqual(TRPProviderKeyResolver.shared.hostKeys.googlePlacesApiKey, "host-places")
    }

    func testInitializeWithoutKeysLeavesTheSharedResolversHostKeysUntouched() {
        let originalHostKeys = TRPProviderKeyResolver.shared.hostKeys
        defer { TRPProviderKeyResolver.shared.hostKeys = originalHostKeys }
        TRPProviderKeyResolver.shared.hostKeys = TRPProviderKeys(mapboxAccessToken: "already-set")

        TRPCoreKit.initialize(baseUrl: "https://example.com",
                              basePath: "v1",
                              apiKey: "test-api-key")

        XCTAssertEqual(TRPProviderKeyResolver.shared.hostKeys.mapboxAccessToken, "already-set")
        XCTAssertNil(TRPProviderKeyResolver.shared.hostKeys.googlePlacesApiKey)
    }

    // MARK: - resolvedKeys / TRPCoreKit.providerKeys

    func testResolvedKeysPrefersTheHostValueForBothKeys() {
        let resolver = makeResolver(plist: { $0 == .mglMapboxAccessToken ? "plist-token" : "plist-places" })
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "host-token", googlePlacesApiKey: "host-places")

        let resolved = resolver.resolvedKeys()

        XCTAssertEqual(resolved.mapboxAccessToken, "host-token")
        XCTAssertEqual(resolved.googlePlacesApiKey, "host-places")
    }

    func testResolvedKeysFallsBackToThePlistWhenTheHostValueIsEmpty() {
        let resolver = makeResolver(plist: { $0 == .mglMapboxAccessToken ? "plist-token" : "plist-places" })
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "", googlePlacesApiKey: "")

        let resolved = resolver.resolvedKeys()

        XCTAssertEqual(resolved.mapboxAccessToken, "plist-token")
        XCTAssertEqual(resolved.googlePlacesApiKey, "plist-places")
    }

    func testResolvedKeysIsNilForBothKeysWhenNeitherHostNorPlistHasAValue() {
        let resolver = makeResolver(plist: { _ in nil })

        let resolved = resolver.resolvedKeys()

        XCTAssertNil(resolved.mapboxAccessToken)
        XCTAssertNil(resolved.googlePlacesApiKey)
    }

    func testCoreKitProviderKeysReflectsTheResolver() {
        let resolver = makeResolver(plist: { _ in nil })
        let coreKit = TRPCoreKit(keyResolver: resolver, mapboxTokenSink: { _ in })
        resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "host-token", googlePlacesApiKey: "host-places")

        XCTAssertEqual(coreKit.providerKeys, TRPProviderKeys(mapboxAccessToken: "host-token", googlePlacesApiKey: "host-places"))
    }

    // MARK: - concurrency

    /// Writes and reads `hostKeys` from many threads at once; the resolver must not crash and the
    /// final value must be one of the values a writer actually wrote.
    func testHostKeysSurvivesConcurrentReadsAndWrites() {
        let resolver = makeResolver(plist: { _ in nil })
        let iterations = 200
        let expectation = self.expectation(description: "concurrentPerform finished")

        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: iterations) { index in
                if index % 2 == 0 {
                    resolver.hostKeys = TRPProviderKeys(mapboxAccessToken: "token-\(index)")
                } else {
                    _ = resolver.hostKeys
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        let finalToken = resolver.hostKeys.mapboxAccessToken
        let possibleValues = (0..<iterations).filter { $0 % 2 == 0 }.map { "token-\($0)" }
        XCTAssertTrue(finalToken == nil || possibleValues.contains(finalToken!))
    }
}
