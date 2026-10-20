import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers `HostedCartActionPresenter`'s hand-off path, used when `ProviderHostedCartParams.settlement` is `.handOff`:
/// the page is shown without polling and the presenter answers once the customer leaves it.
@MainActor
final class HostedCartHandOffTests: XCTestCase {
    private typealias BC = BookingContract

    private func makeHandOffAction(id: String = "act_hand_off") -> BC.NextAction {
        .providerHostedCart(BC.NextAction.Payload(
            id: id, params: BC.ProviderHostedCartParams(url: "about:blank", pollIntervalSeconds: 3, settlement: .handOff)))
    }

    /// Pushes the hand-off screen on a windowed navigation controller and waits for it to appear.
    private func presentHandOff(_ presenter: HostedCartActionPresenter) -> (Task<NextActionOutcome, Never>,
                                                                            UINavigationController, UIWindow) {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let window = UIWindow()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        let action = makeHandOffAction()
        let task = Task { await presenter.present(action, on: navigationController) }
        return (task, navigationController, window)
    }

    private func waitForScreen(on navigationController: UINavigationController) async -> HostedCartPaymentViewController? {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if let screen = navigationController.topViewController as? HostedCartPaymentViewController { return screen }
            await Task.yield()
        }
        return nil
    }

    func testLeavingTheHandedOffPageAnswersHandedOffWithoutCallingSettlement() async throws {
        var settlementCalls = 0
        let presenter = HostedCartActionPresenter(settlement: { _ in settlementCalls += 1; return .pending },
                                                  theme: TRPBookingTheme(), text: TRPBookingText())
        let (task, navigationController, _) = presentHandOff(presenter)
        let foundScreen = await waitForScreen(on: navigationController)
        let screen = try XCTUnwrap(foundScreen)
        XCTAssertNil(screen.polling)

        navigationController.popViewController(animated: false)
        screen.viewDidDisappear(false)

        let outcome = await task.value
        guard case .result(let result) = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(result, .status(.handedOff))
        XCTAssertEqual(settlementCalls, 0)
    }

    func testHandedOffPageShowsADoneButtonThatPopsTheScreen() async throws {
        let presenter = HostedCartActionPresenter(settlement: { _ in .pending }, theme: TRPBookingTheme(), text: TRPBookingText())
        let (task, navigationController, _) = presentHandOff(presenter)
        let foundScreen = await waitForScreen(on: navigationController)
        let screen = try XCTUnwrap(foundScreen)
        screen.loadViewIfNeeded()

        let doneButton = try XCTUnwrap(screen.navigationItem.rightBarButtonItem)
        XCTAssertEqual(doneButton.title, TRPBookingText()(.hostedCheckoutDone))

        _ = doneButton.target?.perform(doneButton.action, with: doneButton)
        screen.viewDidDisappear(false)

        let outcome = await task.value
        guard case .result(let result) = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(result, .status(.handedOff))
    }

    func testDoneButtonIsShownOnlyWhenRequested() {
        let defaultScreen = HostedCartPaymentViewController(
            pageURL: URL(string: "about:blank")!, theme: TRPBookingTheme(), text: TRPBookingText())
        defaultScreen.loadViewIfNeeded()
        XCTAssertNil(defaultScreen.navigationItem.rightBarButtonItem)

        let doneScreen = HostedCartPaymentViewController(
            pageURL: URL(string: "about:blank")!, showsDoneButton: true, theme: TRPBookingTheme(), text: TRPBookingText())
        doneScreen.loadViewIfNeeded()
        XCTAssertNotNil(doneScreen.navigationItem.rightBarButtonItem)
    }

    func testOnLeaveFiresOnlyOnceEvenWhenTheScreenIsDeallocatedAfterwards() async throws {
        var leaveCount = 0
        var screen: HostedCartPaymentViewController? = HostedCartPaymentViewController(
            pageURL: URL(string: "about:blank")!, theme: TRPBookingTheme(), text: TRPBookingText())
        screen?.onLeave = { leaveCount += 1 }

        screen?.viewDidDisappear(false)
        screen = nil

        XCTAssertEqual(leaveCount, 1)
    }
}
