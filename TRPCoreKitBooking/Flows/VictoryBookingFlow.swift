import UIKit
import TRPBookingKit

/// Ticket Evolution: ticket group, quantity, a fresh quote, the buyer, then a Braintree nonce for the order.
@MainActor
final class VictoryBookingFlow: BookingFlow {

    private let context: BookingFlowContext
    private let checkout: VictoryCheckout
    private let eventId: Int
    private let payment: PaymentNonceProviding
    private var offers: VictoryEventOffers?
    private var text: TRPBookingText { context.text }
    private var currency: String { VictoryCheckout.currency }

    init(context: BookingFlowContext, checkout: VictoryCheckout, eventId: Int, payment: PaymentNonceProviding) {
        self.context = context
        self.checkout = checkout
        self.eventId = eventId
        self.payment = payment
    }

    func start(on root: BookingBaseViewController) {
        let checkout = checkout
        let eventId = eventId
        context.perform(on: root, {
            try await checkout.offers(eventId: eventId)
        }, then: { [weak self] offers in
            self?.showGroups(offers, root: root)
        })
    }

    private func showGroups(_ offers: VictoryEventOffers, root: BookingBaseViewController) {
        self.offers = offers
        let groups = offers.ticketGroups
            .filter { !$0.sellableQuantities.isEmpty }
            .sorted { ($0.retailPrice ?? .greatestFiniteMagnitude) < ($1.retailPrice ?? .greatestFiniteMagnitude) }
        guard !groups.isEmpty else {
            root.show(message: text(.soldOut))
            return
        }
        let items = groups.map { group in
            BookingChoiceItem(id: String(group.id), title: seatTitle(group),
                              subtitle: group.publicNotes,
                              detail: context.formatting.price(group.retailPrice, currency: currency).map { text(.perPerson, $0) })
        }
        let list = BookingChoiceListViewController(title: text(.chooseTickets), items: items,
                                                   message: offers.event.name, theme: context.theme, text: text)
        list.onSelect = { [weak self, weak list] item in
            guard let self, let list, let group = groups.first(where: { String($0.id) == item.id }) else { return }
            self.chooseQuantity(group, from: list)
        }
        context.navigationController.setViewControllers([list], animated: false)
    }

    private func seatTitle(_ group: VictoryTicketGroup) -> String {
        let parts = [group.section.map { text(.ticketSection, $0) }, group.row.map { text(.ticketRow, $0) }].compactMap { $0 }
        return parts.isEmpty ? text(.chooseTickets) : parts.joined(separator: " · ")
    }

    private func chooseQuantity(_ group: VictoryTicketGroup, from list: BookingBaseViewController) {
        let quantities = group.sellableQuantities
        if quantities.count == 1, let quantity = quantities.first {
            quote(group, quantity: quantity, from: list)
            return
        }
        let items = quantities.map { quantity in
            BookingChoiceItem(id: String(quantity), title: "\(quantity)",
                              detail: context.formatting.price(group.total(quantity: quantity), currency: currency))
        }
        let quantityList = BookingChoiceListViewController(title: text(.chooseQuantity), items: items, theme: context.theme, text: text)
        quantityList.onSelect = { [weak self, weak quantityList] item in
            guard let self, let quantityList, let quantity = Int(item.id) else { return }
            self.quote(group, quantity: quantity, from: quantityList)
        }
        context.push(quantityList)
    }

    private func quote(_ group: VictoryTicketGroup, quantity: Int, from screen: BookingBaseViewController) {
        let checkout = checkout
        let eventId = eventId
        context.perform(on: screen, {
            try await checkout.quote(eventId: eventId, group: group, quantity: quantity)
        }, then: { [weak self] quote in
            self?.showSummary(quote, anchor: screen)
        })
    }

    private func summaryRows(_ quote: VictoryQuote) -> [BookingSummaryRow] {
        var rows: [BookingSummaryRow] = []
        if let eventDate = offers?.eventDate {
            rows.append(BookingSummaryRow(title: text(.date), value: context.formatting.day(eventDate)))
        }
        rows += [
            BookingSummaryRow(title: seatTitle(quote.group), value: "× \(quote.quantity)"),
            BookingSummaryRow(title: text(.subtotal), value: context.price(quote.subtotal, currency: quote.currency)),
            BookingSummaryRow(title: text(.serviceFee), value: context.price(quote.serviceFee, currency: quote.currency)),
            BookingSummaryRow(title: text(.tax), value: context.price(quote.tax, currency: quote.currency)),
            BookingSummaryRow(title: text(.total), value: context.price(quote.total, currency: quote.currency), isEmphasized: true)
        ]
        return rows
    }

    private func showSummary(_ quote: VictoryQuote, anchor: BookingBaseViewController) {
        let notes = quote.group.publicNotes.map { [(title: text(.ticketNotes), body: $0)] } ?? []
        let summary = BookingSummaryViewController(title: text(.summary), rows: summaryRows(quote), notes: notes, deadline: nil,
                                                   actionTitle: text(.continueAction), theme: context.theme, text: text)
        summary.onConfirm = { [weak self] in
            self?.enterBuyer(quote, anchor: anchor)
        }
        context.push(summary)
    }

    private func enterBuyer(_ quote: VictoryQuote, anchor: BookingBaseViewController) {
        let builder = VictoryFormBuilder(text: text)
        let form = BookingFormViewController(title: text(.details), sections: builder.sections,
                                             submitTitle: text(.pay, context.price(quote.total, currency: quote.currency)),
                                             theme: context.theme, text: text)
        form.onSubmit = { [weak self, weak form] values in
            guard let self, let form else { return }
            self.order(quote, buyer: builder.buyer(from: values), form: form, anchor: anchor)
        }
        context.push(form)
    }

    private func order(_ quote: VictoryQuote, buyer: VictoryBuyer, form: BookingFormViewController, anchor: BookingBaseViewController) {
        let checkout = checkout
        let payment = payment
        let eventDate = offers?.eventDate
        let activityId = context.activityId
        let title = context.title
        context.perform(on: form, {
            try await checkout.order(quote, buyer: buyer, eventDate: eventDate, activityId: activityId, title: title, payment: payment)
        }, handle: { [weak self, weak form] error in
            guard let self, let form else { return false }
            if case BookingError.rejected = error {
                self.context.showAlert(on: form, message: self.text(.priceChanged)) { [weak self] in self?.context.popTo(anchor) }
                return true
            }
            return self.context.handleCheckoutError(error, rewindTo: anchor, on: form)
        }, then: { [weak self] outcome in
            self?.finished(outcome, quote: quote)
        })
    }

    private func finished(_ outcome: VictoryOrderOutcome, quote: VictoryQuote) {
        let rows = [BookingSummaryRow(title: text(.total), value: context.price(outcome.order.total ?? quote.total, currency: outcome.currency))]
        switch outcome.order.state {
        case .accepted, .completed:
            context.showResult(.success, rows: rows, voucherURL: outcome.order.url, reference: outcome.reference)
        case .rejected, .cancelled:
            context.showResult(.failure, message: text(.statusFailed), reference: outcome.reference)
        case .pending, .other:
            context.showResult(.pending, rows: rows, reference: outcome.reference)
        }
    }
}
