import UIKit
import TRPBookingKit

/// Viator: day, travellers, option and time, booking questions, a held cart, then Viator's own payment page.
@MainActor
final class ViatorBookingFlow: BookingFlow {

    static let searchDays = 60
    static let defaultMaximumTravelers = 15

    private let context: BookingFlowContext
    private let checkout: ViatorCheckout
    private let productCode: String
    private let credentials: ViatorCredentials
    private var product: ViatorProductContext?
    private var date: BookingDate?
    private var paxMix: [ViatorPax] = []
    private var text: TRPBookingText { context.text }
    private var currency: String { context.booking.configuration.preferredCurrency }

    init(context: BookingFlowContext, checkout: ViatorCheckout, productCode: String, credentials: ViatorCredentials) {
        self.context = context
        self.checkout = checkout
        self.productCode = productCode
        self.credentials = credentials
    }

    func start(on root: BookingBaseViewController) {
        let checkout = checkout
        let productCode = productCode
        context.perform(on: root, {
            try await checkout.context(productCode: productCode)
        }, then: { [weak self] product in
            self?.loaded(product, root: root)
        })
    }

    private func loaded(_ product: ViatorProductContext, root: BookingBaseViewController) {
        self.product = product
        let calendar = product.calendar
        let requested = BookingDate(date: context.date, timeZone: product.product.timeZone)
        if calendar.isAvailable(requested) {
            date = requested
            choosePassengers(replacingRoot: true)
            return
        }
        let earliest = max(calendar.earliestBookableDate(), requested)
        let dates = calendar.availableDates(from: earliest, through: earliest.adding(days: Self.searchDays - 1))
        guard !dates.isEmpty else {
            root.show(message: text(.noAvailability))
            return
        }
        let items = dates.map { BookingChoiceItem(id: $0.description, title: context.formatting.day($0)) }
        let list = BookingChoiceListViewController(title: text(.chooseDate), items: items, message: text(.noAvailability),
                                                   theme: context.theme, text: text)
        list.onSelect = { [weak self] item in
            self?.date = BookingDate(item.id)
            self?.choosePassengers(replacingRoot: false)
        }
        context.navigationController.setViewControllers([list], animated: false)
    }

    private func choosePassengers(replacingRoot: Bool) {
        guard let product else { return }
        let rules = product.product.ageBands
        let productMaximum = product.product.maxTravelersPerBooking ?? Self.defaultMaximumTravelers
        let leadBand = rules.first { $0.ageBand == .adult || $0.ageBand == .traveler }?.ageBand
        let fields = rules.map { rule in
            BookingFormField(id: rule.ageBand.rawValue,
                             title: ViatorFormBuilder.bandTitle(rule.ageBand) ?? text(.travellers),
                             detail: BookingFlowContext.ageRange(minimum: rule.startAge, maximum: rule.endAge).map { text(.ageRange, $0) },
                             kind: .stepper(minimum: 0, maximum: min(productMaximum, rule.maxTravelersPerBooking ?? productMaximum)),
                             isRequired: false,
                             initialValues: [String(rule.ageBand == leadBand ? max(1, rule.minTravelersPerBooking) : 0)])
        }
        let form = BookingFormViewController(title: text(.travellers), sections: [BookingFormSection(fields: fields)],
                                             submitTitle: text(.continueAction), theme: context.theme, text: text)
        form.onSubmit = { [weak self, weak form] values in
            guard let self, let form else { return }
            let paxMix = rules.map { ViatorPax(ageBand: $0.ageBand, numberOfTravelers: values.int($0.ageBand.rawValue)) }
                .filter { $0.numberOfTravelers > 0 }
            let issues = ViatorSelectionValidator().paxIssues(paxMix, product: product.product).map(\.description)
            form.setIssues(issues)
            guard issues.isEmpty else { return }
            self.paxMix = paxMix
            self.loadOptions(from: form)
        }
        if replacingRoot {
            context.navigationController.setViewControllers([form], animated: false)
        } else {
            context.push(form)
        }
    }

    private func loadOptions(from form: BookingFormViewController) {
        guard let product, let date else { return }
        let checkout = checkout
        let paxMix = paxMix
        let currency = currency
        context.perform(on: form, {
            try await checkout.availability(for: product, on: date, paxMix: paxMix, currency: currency)
        }, then: { [weak self] availability in
            self?.showOptions(availability, from: form)
        })
    }

    private func showOptions(_ availability: ViatorAvailability, from form: BookingFormViewController) {
        guard let product else { return }
        let items = availability.bookableItems.filter(\.available)
        guard !items.isEmpty else {
            form.show(message: text(.noAvailability))
            return
        }
        if items.count == 1, let item = items.first {
            enterDetails(item, currency: availability.currency)
            return
        }
        let choices = items.enumerated().map { index, item in
            BookingChoiceItem(id: String(index),
                              title: product.product.option(code: item.productOptionCode)?.title ?? product.product.title ?? item.productOptionCode,
                              subtitle: item.startTime.map(context.formatting.time),
                              detail: context.formatting.price(item.totalPrice?.recommendedRetailPrice, currency: availability.currency))
        }
        let list = BookingChoiceListViewController(title: text(.chooseOption), items: choices, theme: context.theme, text: text)
        list.onSelect = { [weak self] choice in
            guard let index = Int(choice.id), items.indices.contains(index) else { return }
            self?.enterDetails(items[index], currency: availability.currency)
        }
        context.push(list)
    }

    private func enterDetails(_ item: ViatorAvailability.Item, currency: String) {
        guard let product else { return }
        let builder = ViatorFormBuilder(context: product, paxMix: paxMix, optionCode: item.productOptionCode, text: text)
        let form = BookingFormViewController(title: text(.details), sections: builder.sections, submitTitle: text(.continueAction),
                                             theme: context.theme, text: text)
        form.onSubmit = { [weak self, weak form] values in
            guard let self, let form else { return }
            let details = builder.details(from: values)
            let issues = ViatorSelectionValidator().answerIssues(details.answers, product: product.product, questions: product.questions,
                                                                 travelerCount: builder.travelerCount).map(\.description)
            form.setIssues(issues)
            guard issues.isEmpty else { return }
            self.hold(item, details: details, currency: currency, from: form)
        }
        context.push(form)
    }

    private func hold(_ item: ViatorAvailability.Item, details: ViatorBookerDetails, currency: String, from form: BookingFormViewController) {
        guard let date else { return }
        let checkout = checkout
        let holdItem = ViatorHoldItem(productCode: productCode, productOptionCode: item.productOptionCode, startTime: item.startTime,
                                      travelDate: date, paxMix: paxMix)
        let activityId = context.activityId
        let title = context.title
        context.perform(on: form, {
            try await checkout.hold(holdItem, currency: currency, activityId: activityId, title: title)
        }, then: { [weak self] hold in
            self?.showSummary(hold, details: details, form: form)
        })
    }

    private func showSummary(_ hold: ViatorCheckoutHold, details: ViatorBookerDetails, form: BookingFormViewController) {
        guard let product else { return }
        var rows = [BookingSummaryRow(title: text(.date), value: context.formatting.day(hold.item.travelDate))]
        if let startTime = hold.item.startTime {
            rows.append(BookingSummaryRow(title: text(.time), value: context.formatting.time(startTime)))
        }
        if let option = product.product.option(code: hold.item.productOptionCode)?.title {
            rows.append(BookingSummaryRow(title: text(.chooseOption), value: option))
        }
        for pax in hold.item.paxMix {
            rows.append(BookingSummaryRow(title: ViatorFormBuilder.bandTitle(pax.ageBand) ?? text(.travellers), value: "× \(pax.numberOfTravelers)"))
        }
        rows.append(BookingSummaryRow(title: text(.total), value: context.price(hold.total, currency: hold.currency), isEmphasized: true))
        let notes = product.product.cancellationPolicy?.description.map { [(title: text(.cancellationPolicy), body: $0)] } ?? []
        let summary = BookingSummaryViewController(title: text(.summary), rows: rows, notes: notes, deadline: hold.deadline,
                                                   actionTitle: text(.payNow), theme: context.theme, text: text)
        summary.onExpired = { [weak self, weak summary] in
            guard let self, let summary else { return }
            self.context.showAlert(on: summary, message: self.text(.holdExpired)) { [weak self] in self?.context.popTo(form) }
        }
        summary.onConfirm = { [weak self, weak summary] in
            guard let self, let summary else { return }
            self.book(hold, details: details, summary: summary, form: form)
        }
        context.push(summary)
    }

    private func book(_ hold: ViatorCheckoutHold, details: ViatorBookerDetails, summary: BookingSummaryViewController,
                      form: BookingFormViewController) {
        guard let product else { return }
        let checkout = checkout
        let presenter = ViatorPaymentPresenter(navigationController: context.navigationController, credentials: credentials,
                                               languageCode: context.booking.configuration.languageCode,
                                               theme: context.theme, text: text)
        context.perform(on: summary, {
            try await checkout.book(hold, details: details, context: product, payment: presenter)
        }, handle: { [weak self, weak summary] error in
            guard let self, let summary else { return false }
            return self.context.handleCheckoutError(error, rewindTo: form, on: summary)
        }, then: { [weak self] outcome in
            self?.finished(outcome)
        })
    }

    private func finished(_ outcome: ViatorBookingOutcome) {
        let rows = [BookingSummaryRow(title: text(.total), value: context.price(outcome.total, currency: outcome.currency))]
        switch outcome.status {
        case .confirmed:
            context.showResult(.success, rows: rows, voucherURL: outcome.voucher?.url, reference: outcome.reference)
        case .rejected, .failed, .cancelled:
            context.showResult(.failure, message: text(.statusFailed), reference: outcome.reference)
        default:
            context.showResult(.pending, rows: rows, voucherURL: outcome.voucher?.url, reference: outcome.reference)
        }
    }
}
