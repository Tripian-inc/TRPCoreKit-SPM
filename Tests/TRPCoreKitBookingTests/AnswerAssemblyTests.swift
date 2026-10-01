import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Fills each step's form with the values a recorded submit sent and checks that it assembles the same request.
final class AnswerAssemblyTests: XCTestCase {

    func testFormsAssembleTheRecordedAnswersAndExpectedAmount() throws {
        for directory in ["viator", "_synthetic/a-full-flow", "_synthetic/f-hold-expired"] {
            let submits = try ContractFixtures.exchanges(in: directory).filter { $0.request.path.contains("/steps/") }
            XCTAssertFalse(submits.isEmpty, directory)
            for exchange in submits {
                let label = "\(directory)/\(exchange.name)"
                let request = try XCTUnwrap(exchange.request.body, label).decode(as: BC.SubmitStepRequest.self)
                let step = try ContractFixtures.answeredStep(for: exchange, in: directory)
                let layout = BlockRegistry.standard.layout(for: step)
                var form = FormState(layout: layout)
                for (id, value) in request.answers.values {
                    XCTAssertTrue(layout.rows.contains { $0.id == id }, "\(label): no row \(id)")
                    form.set(value, for: id)
                }
                XCTAssertEqual(form.answers, request.answers, label)
                XCTAssertTrue(form.problems().isEmpty, "\(label): \(form.problems())")
                XCTAssertEqual(layout.displayedAmount, request.expectedAmount, label)
            }
        }
    }
}
