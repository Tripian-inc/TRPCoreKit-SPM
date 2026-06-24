import Foundation
import UIKit

final class TRPUserAgentURLProtocol: URLProtocol {

    private static var registeredHosts: Set<String> = []
    private static let handledKey = "TRPUserAgentURLProtocolHandled"

    private static let userAgentValue: String = {
        let bundle = Bundle.main
        let appBundleId = bundle.bundleIdentifier ?? "unknown"
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        return "TRPCoreKit (\(appBundleId)/\(appVersion); Build/\(buildNumber); iOS/\(osVersion); \(deviceModel))"
    }()

    private var sessionTask: URLSessionDataTask?

    static func register(host: String) {
        let normalized = host.lowercased()
        guard !normalized.isEmpty else { return }
        let didInsert = registeredHosts.insert(normalized).inserted
        if registeredHosts.count == 1 || didInsert {
            URLProtocol.registerClass(TRPUserAgentURLProtocol.self)
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host?.lowercased() else { return false }
        if URLProtocol.property(forKey: handledKey, in: request) as? Bool == true { return false }
        return registeredHosts.contains(host)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)
        mutableRequest.setValue(Self.userAgentValue, forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: .default)
        sessionTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        sessionTask?.resume()
    }

    override func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
    }
}
