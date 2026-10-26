import XCTest
import UIKit
@testable import TRPCoreKit

/// Pins keyboard dismissal in `AddPlanActivityListingVC`: the table opts into drag-to-dismiss,
/// and selecting a row resigns the keyboard before notifying the host.
final class AddPlanActivityListingVCKeyboardTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        super.tearDown()
    }

    private func makeLoadedVC() -> AddPlanActivityListingVC {
        let vc = AddPlanActivityListingVC()
        vc.viewModel = AddPlanActivityListingViewModel(planData: AddPlanData())
        vc.loadViewIfNeeded()
        return vc
    }

    private func findTableView(in view: UIView) -> UITableView? {
        if let tableView = view as? UITableView { return tableView }
        for subview in view.subviews {
            if let found = findTableView(in: subview) { return found }
        }
        return nil
    }

    func testTableViewKeyboardDismissModeIsOnDrag() {
        let vc = makeLoadedVC()

        let tableView = findTableView(in: vc.view)
        XCTAssertEqual(tableView?.keyboardDismissMode, .onDrag)
    }

    func testDidSelectRowResignsKeyboard() {
        let vc = makeLoadedVC()

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = vc
        window.isHidden = false
        window.makeKeyAndVisible()

        let textField = UITextField()
        vc.view.addSubview(textField)
        textField.becomeFirstResponder()
        XCTAssertTrue(textField.isFirstResponder)

        vc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertFalse(textField.isFirstResponder)
    }
}
