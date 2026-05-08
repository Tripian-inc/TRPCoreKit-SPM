import Foundation

public struct TripianNavigateParams {
    public let type: String
    public let locator: String?
    public let detailURL: String?
    public let productId: String?
    public let date: String?

    public init(type: String, locator: String? = nil, detailURL: String? = nil, productId: String? = nil, date: String? = nil) {
        self.type = type
        self.locator = locator
        self.detailURL = detailURL
        self.productId = productId
        self.date = date
    }
}

public class TripianNavigateBridge {
    public static let shared = TripianNavigateBridge()
    public var onNavigate: ((TripianNavigateParams) -> Void)?
    private init() {}
}
