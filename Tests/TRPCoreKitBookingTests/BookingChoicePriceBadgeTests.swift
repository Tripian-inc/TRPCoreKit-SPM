import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers price/badge carried from a contract choice option through to the rendered row, and that a disabled
/// option cannot be selected.
@MainActor
final class BookingChoicePriceBadgeTests: XCTestCase {
    private typealias BC = BookingContract

    private func makeOption(value: String, title: String, price: BC.Money?, badge: String?,
                            disabled: Bool? = nil) -> BC.ChoiceBlock.Option {
        BC.ChoiceBlock.Option(value: value, title: title, subtitle: nil, price: price, badge: badge, disabled: disabled)
    }

    func testPickOptionCarriesFormattedPriceAndBadge() {
        let money = BC.Money(amount: "60.00", currency: "USD")
        let option = makeOption(value: "TG_9003", title: "In hand", price: money, badge: "In hand")

        let pickOption = BookingPickOption(option)

        XCTAssertEqual(pickOption.price, BookingFormatting().price(money))
        XCTAssertEqual(pickOption.badge, "In hand")
        XCTAssertTrue(pickOption.isEnabled)
    }

    func testDisabledOptionIsNotEnabled() {
        let option = makeOption(value: "TG_9001", title: "E-ticket", price: nil, badge: "E-ticket", disabled: true)

        let pickOption = BookingPickOption(option)

        XCTAssertFalse(pickOption.isEnabled)
    }

    func testChoiceCellShowsPriceAndBadge() {
        let item = BookingChoiceItem(id: "TG_9003", title: "Ticket Group 1", price: "$60.00", badge: "In hand")
        let cell = BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)

        cell.configure(with: item, theme: TRPBookingTheme())

        XCTAssertEqual(cell.priceLabel.text, "$60.00")
        XCTAssertFalse(cell.priceLabel.isHidden)
        XCTAssertEqual(cell.badgeLabel.text, "In hand")
        XCTAssertFalse(cell.badgeLabel.isHidden)
    }

    func testDisabledChoiceCellIsDimmedWhileEnabledOneIsFull() {
        let enabledCell = BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)
        let disabledCell = BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)

        enabledCell.configure(with: BookingChoiceItem(id: "a", title: "Enabled", isEnabled: true), theme: TRPBookingTheme())
        disabledCell.configure(with: BookingChoiceItem(id: "b", title: "Disabled", isEnabled: false), theme: TRPBookingTheme())

        XCTAssertEqual(enabledCell.contentView.subviews.first?.alpha, 1)
        XCTAssertEqual(disabledCell.contentView.subviews.first?.alpha, 0.5)
    }

    func testDisabledChoiceCellAccessibilityTraitsIncludeNotEnabled() {
        let enabledCell = BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)
        let disabledCell = BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)

        enabledCell.configure(with: BookingChoiceItem(id: "a", title: "Enabled", isEnabled: true), theme: TRPBookingTheme())
        disabledCell.configure(with: BookingChoiceItem(id: "b", title: "Disabled", isEnabled: false), theme: TRPBookingTheme())

        XCTAssertEqual(enabledCell.accessibilityTraits, .button)
        XCTAssertTrue(disabledCell.accessibilityTraits.contains(.notEnabled))
        XCTAssertTrue(disabledCell.accessibilityTraits.contains(.button))
    }

    func testDisabledRowCannotBeSelected() {
        let items = [
            BookingChoiceItem(id: "enabled", title: "Enabled", isEnabled: true),
            BookingChoiceItem(id: "disabled", title: "Disabled", isEnabled: false)
        ]
        let list = BookingChoiceListViewController(title: "Pick", items: items, theme: TRPBookingTheme(), text: TRPBookingText())
        list.loadViewIfNeeded()

        var selected: BookingChoiceItem?
        list.onSelect = { selected = $0 }

        let disabledIndexPath = IndexPath(row: 1, section: 0)
        XCTAssertFalse(list.tableView(UITableView(), shouldHighlightRowAt: disabledIndexPath))
        XCTAssertNil(list.tableView(UITableView(), willSelectRowAt: disabledIndexPath))

        list.tableView(UITableView(), didSelectRowAt: disabledIndexPath)
        XCTAssertNil(selected)

        let enabledIndexPath = IndexPath(row: 0, section: 0)
        XCTAssertTrue(list.tableView(UITableView(), shouldHighlightRowAt: enabledIndexPath))
        XCTAssertEqual(list.tableView(UITableView(), willSelectRowAt: enabledIndexPath), enabledIndexPath)
        list.tableView(UITableView(), didSelectRowAt: enabledIndexPath)
        XCTAssertEqual(selected?.id, "enabled")
    }
}
