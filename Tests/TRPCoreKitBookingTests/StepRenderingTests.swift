import UIKit
import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Lays out and renders every step of the provider-neutral fixtures with the standard registries.
@MainActor
final class StepRenderingTests: XCTestCase {

    private let registry = BlockRegistry.standard

    func testEveryViatorAndFullFlowStepIsRenderable() throws {
        for directory in ["viator", "_synthetic/a-full-flow"] {
            let steps = try ContractFixtures.steps(in: directory)
            XCTAssertFalse(steps.isEmpty, directory)
            for (name, step, _) in steps {
                let layout = registry.layout(for: step)
                XCTAssertTrue(layout.isRenderable, "\(directory)/\(name): \(layout.unsupported)")
                XCTAssertEqual(layout.groups.map(\.id), step.blocks.map(\.id), "\(directory)/\(name)")
            }
        }
    }

    func testEveryStepScreenLoadsWithOneCardPerVisibleGroup() throws {
        for directory in ["viator", "_synthetic/a-full-flow", "_synthetic/f-hold-expired"] {
            for (name, step, checkout) in try ContractFixtures.steps(in: directory) {
                let screen = CheckoutStepViewController(step: step, layout: registry.layout(for: step), checkout: checkout,
                                                        canGoBack: true, canExtend: true, now: Date.init,
                                                        theme: TRPBookingTheme(), text: TRPBookingText())
                screen.loadViewIfNeeded()
                XCTAssertFalse(screen.form.visibleGroups.isEmpty, "\(directory)/\(name)")
                XCTAssertEqual(screen.step, step)
            }
        }
    }

    func testConditionallyVisibleFieldsStartHiddenAndAppearWhenTheirConditionHolds() throws {
        let details = try XCTUnwrap(ContractFixtures.steps(in: "_synthetic/a-full-flow").first { $0.step.id == "details" })
        var form = FormState(layout: registry.layout(for: details.step))
        let newsletterEmail = try XCTUnwrap(form.layout.rows.first { $0.id == "newsletterEmail" })

        XCTAssertFalse(form.isVisible(newsletterEmail))
        XCTAssertFalse(form.visibleGroups.contains { $0.id == "newsletterEmail" })
        XCTAssertNil(form.answers["newsletterEmail"])

        form.set(.bool(true), for: "newsletter")
        form.set(.string("ada@example.com"), for: "newsletterEmail")
        XCTAssertTrue(form.isVisible(newsletterEmail))
        XCTAssertEqual(form.answers["newsletterEmail"], .string("ada@example.com"))

        form.set(.bool(false), for: "newsletter")
        XCTAssertNil(form.answers["newsletterEmail"])
    }

    func testRequiredRowsReportProblemsUntilAnswered() throws {
        let date = try XCTUnwrap(ContractFixtures.steps(in: "viator").first { $0.step.id == "date" })
        var form = FormState(layout: registry.layout(for: date.step))
        XCTAssertEqual(form.problems()["date"], .required)
        form.set(.string("2026-10-15"), for: "date")
        XCTAssertTrue(form.problems().isEmpty)
    }

    func testVictoryHostedTicketsStepRendersTheSeatingChartAndInfoNotices() throws {
        let exchange = try ContractFixtures.exchange("_synthetic/victory-hosted", "01-create")
        let step = try XCTUnwrap(ContractFixtures.checkout(of: exchange)?.currentStep)
        let layout = registry.layout(for: step)

        XCTAssertTrue(layout.isRenderable, "\(layout.unsupported)")

        let imageRow = try XCTUnwrap(layout.rows.first { row in
            if case .image = row.kind { return true }
            return false
        })
        guard case .image(let imageBlock) = imageRow.kind else { return XCTFail("expected an image row") }
        XCTAssertEqual(imageBlock.aspectRatio, 1.5)

        let noticeRows = layout.rows.compactMap { row -> BookingContract.NoticeBlock? in
            guard case .notice(let notice) = row.kind else { return nil }
            return notice
        }
        XCTAssertFalse(noticeRows.isEmpty)
        for notice in noticeRows {
            XCTAssertEqual(notice.tone.value, .info)
        }
    }

    func testUnknownBlocksFallBack() throws {
        let exchange = try ContractFixtures.exchange("_synthetic/g-forward-compat", "01-unknown-blocks")
        let step = try XCTUnwrap(ContractFixtures.checkout(of: exchange)?.currentStep)
        let layout = registry.layout(for: step)
        XCTAssertFalse(layout.isRenderable)
        XCTAssertFalse(layout.unsupported.isEmpty)
    }

    func testAnUnknownNextActionHasNoPresenter() throws {
        let exchange = try ContractFixtures.exchange("_synthetic/g-forward-compat", "02-unknown-action")
        let action = try XCTUnwrap(ContractFixtures.checkout(of: exchange)?.nextAction)
        let actions = NextActionRegistry.standard(payments: BookingPaymentPresenters(), lang: "en",
                                                  theme: TRPBookingTheme(), text: TRPBookingText())
        XCTAssertNil(actions.presenter(for: action))
    }

    func testARegisteredRendererTakesOverAnUnknownBlock() throws {
        let exchange = try ContractFixtures.exchange("_synthetic/g-forward-compat", "01-unknown-blocks")
        let step = try XCTUnwrap(ContractFixtures.checkout(of: exchange)?.currentStep)
        var extended = registry
        extended.register(NoticeOnlyRenderer(type: "seat_map"))
        XCTAssertEqual(registry.layout(for: step).unsupported, ["seat_map"])
        XCTAssertEqual(extended.layout(for: step).unsupported, ["seat_map"],
                       "a block asking for a newer version than the renderer speaks still falls back")

        let firstVersion = try Self.removingRequires(from: step)
        XCTAssertEqual(registry.layout(for: firstVersion).unsupported, ["seat_map"])
        let layout = extended.layout(for: firstVersion)
        XCTAssertTrue(layout.isRenderable, "\(layout.unsupported)")
        XCTAssertTrue(layout.groups.contains { $0.id == "seats" })
    }

    private static func removingRequires(from step: BookingContract.Step) throws -> BookingContract.Step {
        guard case .object(var object) = try BookingContract.JSONValue(encoding: step),
              case .array(let blocks) = object["blocks"] else { throw CocoaError(.coderInvalidValue) }
        object["blocks"] = .array(blocks.map { block in
            guard case .object(var members) = block else { return block }
            members["requires"] = nil
            return .object(members)
        })
        return try BookingContract.JSONValue.object(object).decode(as: BookingContract.Step.self)
    }
}

/// Renders any block as a notice, standing in for a renderer a host registers.
private struct NoticeOnlyRenderer: BlockRenderer {
    let type: String
    var producesAnswer: Bool { false }

    func rows(for block: BookingContract.Block, in registry: BlockRegistry) -> [FormRow]? {
        [FormRow(id: block.id, kind: .notice(BookingContract.NoticeBlock(id: block.id, tone: .init(.info), text: type)))]
    }
}
