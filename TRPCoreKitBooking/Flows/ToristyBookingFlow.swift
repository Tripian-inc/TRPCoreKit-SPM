import UIKit
import TRPBookingKit

/// Toristy: day, departure, rate, passengers, details, a held cart, then our own card payment.
@MainActor
final class ToristyBookingFlow: BookingFlow {

    static let searchDays = 30

    private let context: BookingFlowContext
    private let checkout: ToristyCheckout
    private let serviceId: Int
    private var information: ToristyBookingInformation?
    private var date: BookingDate?
    private var startTime: ToristyStartTime?
    private var rate: ToristyRate?
    private var counts: [String: Int] = [:]
    private var currency: String { information?.currency ?? context.booking.configuration.preferredCurrency }
    private var text: TRPBookingText { context.text }

    init(context: BookingFlowContext, checkout: ToristyCheckout, serviceId: Int) {
        self.context = context
        self.checkout = checkout
        self.serviceId = serviceId
    }

    func start(on root: BookingBaseViewController) {
        let today = BookingDate(date: Date())
        let requested = max(BookingDate(date: context.date), today)
        let checkout = checkout
        let serviceId = serviceId
        let currency = context.booking.configuration.preferredCurrency
        context.perform(on: root, {
            async let information = checkout.bookingInformation(serviceId: serviceId, currency: currency)
            async let availability = checkout.availability(serviceId: serviceId, from: requested,
                                                          through: requested.adding(days: Self.searchDays - 1))
            return try await (information, availability)
        }, then: { [weak self] information, availability in
            self?.loaded(information, availability: availability, requested: requested, root: root)
        })
    }

    private func loaded(_ information: ToristyBookingInformation, availability: ToristyAvailability, requested: BookingDate,
                        root: BookingBaseViewController) {
        self.information = information
        if let day = availability.day(requested), !day.bookableTimes.isEmpty {
            showTimes(day, replacing: root)
            return
        }
        let days = availability.days.filter { !$0.bookableTimes.isEmpty }
        guard !days.isEmpty else {
            root.show(message: text(.noAvailability))
            return
        }
        let items = days.map { day in
            BookingChoiceItem(id: day.date.description, title: context.formatting.day(day.date),
                              subtitle: day.bookableTimes.map { context.formatting.time($0.time) }.joined(separator: ", "))
        }
        let list = BookingChoiceListViewController(title: text(.chooseDate), items: items, message: text(.noAvailability),
                                                   theme: context.theme, text: text)
        list.onSelect = { [weak self] item in
            guard let day = days.first(where: { $0.date.description == item.id }) else { return }
            self?.showTimes(day, replacing: nil)
        }
        context.navigationController.setViewControllers([list], animated: false)
    }

    private func showTimes(_ day: ToristyAvailabilityDay, replacing root: UIViewController?) {
        date = day.date
        let times = day.bookableTimes
        let items = times.map { time in
            BookingChoiceItem(id: String(time.id), title: context.formatting.time(time.time),
                              subtitle: time.seatsLeft.map { text(.seatsLeft, $0) } ?? text(.unlimitedSeats),
                              detail: startingPrice(at: time))
        }
        let list = BookingChoiceListViewController(title: context.formatting.day(day.date), items: items,
                                                   theme: context.theme, text: text)
        list.onSelect = { [weak self] item in
            guard let time = times.first(where: { String($0.id) == item.id }) else { return }
            self?.chooseRate(at: time)
        }
        if root != nil {
            context.navigationController.setViewControllers([list], animated: false)
        } else {
            context.push(list)
        }
    }

    private func rates(at time: ToristyStartTime) -> [ToristyRate] {
        (information?.rates ?? []).filter { $0.applies(toStartTimeId: time.id) }
    }

    private func startingPrice(at time: ToristyStartTime) -> String? {
        let prices = rates(at: time).compactMap { $0.startingPrice ?? $0.prices.compactMap(\.price).min() }
        return prices.min().flatMap { context.formatting.price($0, currency: currency) }.map { text(.fromPrice, $0) }
    }

    private func chooseRate(at time: ToristyStartTime) {
        startTime = time
        let rates = rates(at: time)
        if rates.count == 1, let rate = rates.first {
            choosePassengers(rate: rate)
            return
        }
        let items = rates.map { rate in
            BookingChoiceItem(id: rate.id, title: rate.name,
                              detail: (rate.startingPrice ?? rate.prices.compactMap(\.price).min())
                                .flatMap { context.formatting.price($0, currency: currency) }
                                .map { text(.fromPrice, $0) })
        }
        let list = BookingChoiceListViewController(title: text(.chooseRate), items: items, theme: context.theme, text: text)
        list.onSelect = { [weak self] item in
            guard let rate = rates.first(where: { $0.id == item.id }) else { return }
            self?.choosePassengers(rate: rate)
        }
        context.push(list)
    }

    private func categories(of rate: ToristyRate) -> [ToristyPricingCategory] {
        let departureRate = startTime?.rate(id: rate.id)
        return rate.prices.filter { departureRate?.accepts(pricingCategoryId: $0.id) ?? true }
    }

    private func choosePassengers(rate: ToristyRate) {
        self.rate = rate
        let categories = categories(of: rate)
        let maximum = startTime?.seatsLeft ?? 20
        let fields = categories.enumerated().map { index, category in
            BookingFormField(id: category.id, title: category.name,
                             detail: [BookingFlowContext.ageRange(minimum: category.minAge, maximum: category.maxAge).map { text(.ageRange, $0) },
                                      context.formatting.price(category.price, currency: currency).map { text(.perPerson, $0) }]
                                .compactMap { $0 }.joined(separator: " · "),
                             kind: .stepper(minimum: 0, maximum: min(maximum, category.maxPerBooking ?? maximum)),
                             isRequired: false,
                             initialValues: [String(index == 0 ? max(1, category.minPerBooking ?? 1) : (counts[category.id] ?? 0))])
        }
        let form = BookingFormViewController(title: text(.travellers), sections: [BookingFormSection(fields: fields)],
                                             submitTitle: text(.continueAction), theme: context.theme, text: text)
        form.onChange = { [weak self, weak form] values in
            form?.setSummary(self?.estimate(values))
        }
        form.onSubmit = { [weak self, weak form] values in
            guard let self, let form else { return }
            let issues = self.passengerIssues(values)
            form.setIssues(issues)
            if issues.isEmpty { self.enterDetails() }
        }
        form.setSummary(estimate(BookingFormValues(sections: [BookingFormSection(fields: fields)])))
        context.push(form)
    }

    private func draft(counts: [String: Int]) -> ToristySelection? {
        guard let information, let rate, let startTime, let date else { return nil }
        let builder = ToristyFormBuilder(information: information, rate: rate, date: date, startTime: startTime,
                                         counts: counts, currency: currency, text: text)
        return builder.selection(from: BookingFormValues())
    }

    private func counts(from values: BookingFormValues) -> [String: Int] {
        guard let rate else { return [:] }
        return Dictionary(uniqueKeysWithValues: categories(of: rate).map { ($0.id, values.int($0.id)) })
    }

    private func estimate(_ values: BookingFormValues) -> String? {
        guard let information, let selection = draft(counts: counts(from: values)), !selection.passengers.isEmpty,
              let estimate = ToristyPriceEstimator().estimate(selection, information: information) else { return nil }
        return context.formatting.price(estimate.total, currency: estimate.currency ?? currency).map { "\(text(.total)): \($0)" }
    }

    private func passengerIssues(_ values: BookingFormValues) -> [String] {
        counts = counts(from: values)
        guard let information, let selection = draft(counts: counts) else { return [] }
        return ToristySelectionValidator().issues(for: selection, information: information).filter { issue in
            switch issue {
            case .notEnoughSeats, .belowMinimumParticipants, .rateBookingBounds, .categoryBookingBounds, .noPassengers,
                 .unknownPricingCategory, .rateNotOfferedAtStartTime, .departureNotBookable:
                return true
            default:
                return false
            }
        }.map(\.description)
    }

    private func enterDetails() {
        guard let information, let rate, let startTime, let date else { return }
        let builder = ToristyFormBuilder(information: information, rate: rate, date: date, startTime: startTime,
                                         counts: counts, currency: currency, text: text)
        let form = BookingFormViewController(title: text(.details), sections: builder.sections, submitTitle: text(.continueAction),
                                             theme: context.theme, text: text)
        form.onSubmit = { [weak self, weak form] values in
            guard let self, let form else { return }
            let selection = builder.selection(from: values)
            let issues = ToristySelectionValidator().issues(for: selection, information: information).map(\.description)
            form.setIssues(issues)
            guard issues.isEmpty else { return }
            self.reserve(selection, email: builder.customerEmail(from: values), from: form)
        }
        context.push(form)
    }

    private func reserve(_ selection: ToristySelection, email: String?, from form: BookingFormViewController) {
        guard let information else { return }
        let checkout = checkout
        let activityId = context.activityId
        let title = context.title
        context.perform(on: form, {
            try await checkout.reserve(selection, information: information, activityId: activityId, title: title)
        }, then: { [weak self] hold in
            self?.showSummary(hold, selection: selection, email: email, form: form)
        })
    }

    private func showSummary(_ hold: ToristyHold, selection: ToristySelection, email: String?, form: BookingFormViewController) {
        var rows = [
            BookingSummaryRow(title: text(.date), value: context.formatting.day(selection.date)),
            BookingSummaryRow(title: text(.time), value: context.formatting.time(selection.startTime.time))
        ]
        if let rate {
            rows.append(BookingSummaryRow(title: text(.chooseRate), value: rate.name))
            for category in rate.prices {
                let count = selection.passengerCounts[category.id] ?? 0
                if count > 0 { rows.append(BookingSummaryRow(title: category.name, value: "× \(count)")) }
            }
        }
        rows.append(BookingSummaryRow(title: text(.total), value: context.price(hold.total, currency: hold.currency), isEmphasized: true))
        let notes = information?.cancellationPolicy.map { [(title: text(.cancellationPolicy), body: $0)] } ?? []
        let summary = BookingSummaryViewController(title: text(.summary), rows: rows, notes: notes, deadline: hold.deadline,
                                                   actionTitle: text(.pay, context.price(hold.total, currency: hold.currency)),
                                                   theme: context.theme, text: text)
        summary.onExpired = { [weak self, weak summary] in
            guard let self, let summary else { return }
            self.context.showAlert(on: summary, message: self.text(.holdExpired)) { [weak self] in self?.context.popTo(form) }
        }
        summary.onConfirm = { [weak self, weak summary] in
            guard let self, let summary else { return }
            self.pay(hold, email: email, summary: summary, form: form)
        }
        context.push(summary)
    }

    private func pay(_ hold: ToristyHold, email: String?, summary: BookingSummaryViewController, form: BookingFormViewController) {
        let checkout = checkout
        context.perform(on: summary, {
            try await checkout.pay(hold, customerEmail: email)
        }, handle: { [weak self, weak summary] error in
            guard let self, let summary else { return false }
            return self.context.handleCheckoutError(error, rewindTo: form, on: summary)
        }, then: { [weak self] booking in
            guard let self else { return }
            self.context.showResult(.success, rows: [
                BookingSummaryRow(title: self.text(.total), value: self.context.price(booking.total, currency: booking.currency))
            ], reference: booking.reference)
        })
    }
}
