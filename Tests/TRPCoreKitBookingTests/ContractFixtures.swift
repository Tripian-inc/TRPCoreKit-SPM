import Foundation
import XCTest
import TRPBookingKit

typealias BC = BookingContract

/// The booking contract fixtures in `Fixtures/Contract`, copied at the commit named in its `PINNED` file.
enum ContractFixtures {

    static var root: URL {
        Bundle.module.resourceURL!.appendingPathComponent("Fixtures/Contract")
    }

    static func exchanges(in directory: String) throws -> [BC.RecordedExchange] {
        try BC.RecordedExchange.load(from: root.appendingPathComponent(directory))
    }

    static func exchange(_ directory: String, _ name: String) throws -> BC.RecordedExchange {
        try XCTUnwrap(exchanges(in: directory).first { $0.name == name }, "\(directory)/\(name)")
    }

    /// The checkout a fixture response carries, either as its payload or inside its error.
    static func checkout(of exchange: BC.RecordedExchange) throws -> BC.Checkout? {
        if exchange.response.status >= 400 {
            return try exchange.response.body.decode(as: BC.Envelope<BC.ErrorData>.self).data?.checkout
        }
        return try exchange.response.body.decode(as: BC.Envelope<BC.Checkout>.self).data
    }

    /// Every step the fixture responses of `directory` show, named after the exchange that returned it.
    static func steps(in directory: String) throws -> [(name: String, step: BC.Step, checkout: BC.Checkout)] {
        try exchanges(in: directory).filter { $0.request.path.contains("/checkouts") }.compactMap { exchange in
            guard let checkout = try checkout(of: exchange), let step = checkout.currentStep else { return nil }
            return (exchange.name, step, checkout)
        }
    }

    /// The step a submit request in `directory` answers: the last one shown before it with the same id.
    static func answeredStep(for exchange: BC.RecordedExchange, in directory: String) throws -> BC.Step {
        let stepId = try XCTUnwrap(exchange.request.path.components(separatedBy: "/steps/").last)
        let earlier = try steps(in: directory).filter { $0.name < exchange.name && $0.step.id == stepId }
        return try XCTUnwrap(earlier.last?.step, "no step \(stepId) before \(exchange.name)")
    }
}

extension BC.JSONValue {

    /// The value with every null object member removed, as an encoder that omits nil optionals writes it.
    var withoutNullMembers: BC.JSONValue {
        switch self {
        case .object(let members):
            return .object(members.filter { $0.value != .null }.mapValues(\.withoutNullMembers))
        case .array(let items):
            return .array(items.map(\.withoutNullMembers))
        default:
            return self
        }
    }
}
