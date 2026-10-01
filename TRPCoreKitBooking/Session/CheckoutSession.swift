import Foundation
import TRPBookingKit

/// Drives one checkout of the booking contract: it sends the customer's steps and action results through a
/// `CheckoutClient`, polls a processing checkout and turns contract errors into states and issues a screen can show.
///
/// The session knows no provider and holds no UI; everything it reports comes through `onChange` and `onIssue`.
@MainActor
public final class CheckoutSession {

    /// Where the checkout stands.
    public enum State: Hashable {
        case idle
        case loading
        case step(BookingContract.Step, BookingContract.Checkout)
        case action(BookingContract.NextAction, BookingContract.Checkout)
        case processing(BookingContract.Checkout)
        case finished(BookingContract.Checkout)
        /// The checkout cannot continue in the app; `fallback` says where it can, `reason` why it stopped.
        case fallback(BookingContract.Fallback?, reason: String)
    }

    /// Something the customer has to be told without the checkout moving on its own.
    public enum Issue: Hashable {
        /// The server rejected these answers.
        case fieldIssues([BookingContract.ErrorData.FieldError])
        /// The checkout changed under the customer; the new one is already the session's state.
        case conflict(BookingContract.ErrorCode)
        /// The payment was declined; the checkout is still waiting for an action.
        case paymentDeclined
        /// The call failed for a reason that may pass; `retry()` sends it again.
        case unavailable
        /// Payment went through but the booking is still being confirmed after polling gave up.
        case awaitingConfirmation
    }

    /// Longest time a processing checkout is polled before the session reports `.awaitingConfirmation`.
    public static let pollingLimit: TimeInterval = 60
    /// Poll interval used when a 202 carries no `Retry-After`.
    public static let defaultPollInterval: TimeInterval = 2

    public private(set) var state: State = .idle {
        didSet { onChange?(state) }
    }
    public private(set) var checkout: BookingContract.Checkout?
    public var onChange: ((State) -> Void)?
    public var onIssue: ((Issue) -> Void)?

    public let lang: String
    public let currency: String
    private let client: CheckoutClient
    public let registry: BlockRegistry
    private let clock: () -> Date
    private let identifiers: () -> UUID
    private let sleep: (TimeInterval) async throws -> Void
    private var failedCall: Call?

    private struct Call {
        let key: BookingContract.IdempotencyKey
        let send: (BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse
    }

    /// - Parameters:
    ///   - registry: decides whether a step can be rendered; a step it cannot render moves the session to `.fallback`.
    ///   - sleep: waits between polls; tests pass one that returns at once.
    public init(client: CheckoutClient, lang: String, currency: String, registry: BlockRegistry = .standard,
                clock: @escaping () -> Date = Date.init, identifiers: @escaping () -> UUID = UUID.init,
                sleep: @escaping (TimeInterval) async throws -> Void = { try await Task.sleep(nanoseconds: UInt64(max(0, $0) * 1_000_000_000)) }) {
        self.client = client
        self.lang = lang
        self.currency = currency
        self.registry = registry
        self.clock = clock
        self.identifiers = identifiers
        self.sleep = sleep
    }

    public var canGoBack: Bool { isOnStep && checkout?.allows(.back) == true }
    public var canExtend: Bool { checkout?.allows(.extend) == true && !isFinished }
    public var canCancel: Bool { checkout?.allows(.cancel) == true && !isFinished }
    /// Whether `retry()` has a failed call to send again.
    public var canRetry: Bool { failedCall != nil }

    /// The current time of the session's clock, for countdowns.
    public var now: Date { clock() }

    /// Creates the checkout; `bookingUuid` defaults to a fresh one.
    public func start(productId: String, optionId: String? = nil, date: String? = nil, bookingUuid: String? = nil) async {
        let request = BookingContract.CreateCheckoutRequest(
            productId: productId, optionId: optionId, date: date, currency: currency,
            bookingUuid: bookingUuid ?? identifiers().uuidString.lowercased(), lang: lang)
        let client = client
        await perform { key in try await client.create(request, idempotencyKey: key) }
    }

    /// Sends the answers of the current step with the displayed amount as `expectedAmount`.
    public func submit(answers: BookingContract.Answers) async {
        guard case .step(let step, let checkout) = state else { return }
        let client = client, lang = lang
        let expectedAmount = registry.layout(for: step).displayedAmount
        await perform { key in
            try await client.submit(checkoutId: checkout.id, stepId: step.id, answers: answers,
                                    expectedAmount: expectedAmount, lang: lang, idempotencyKey: key)
        }
    }

    /// Returns to the previous step.
    public func back() async {
        guard case .step(let step, let checkout) = state, canGoBack else { return }
        let client = client, lang = lang
        await perform { key in
            try await client.back(checkoutId: checkout.id, fromStepId: step.id, lang: lang, idempotencyKey: key)
        }
    }

    /// Extends the hold.
    public func extend() async {
        guard let checkout, canExtend else { return }
        let client = client, lang = lang
        await perform { key in try await client.extend(checkoutId: checkout.id, lang: lang, idempotencyKey: key) }
    }

    /// Cancels the checkout.
    public func cancel() async {
        guard let checkout, canCancel else { return }
        let client = client, lang = lang
        await perform { key in try await client.cancel(checkoutId: checkout.id, lang: lang, idempotencyKey: key) }
    }

    /// Reports the result of `action`.
    public func complete(action: BookingContract.NextAction, result: BookingContract.ActionResult) async {
        guard let checkout else { return }
        let client = client, lang = lang
        await perform { key in
            try await client.action(checkoutId: checkout.id, actionId: action.id, result: result, lang: lang,
                                    idempotencyKey: key)
        }
    }

    /// Reloads the checkout, polling again when it is still processing.
    public func refresh() async {
        guard let checkout else { return }
        let previous = state
        state = .loading
        do {
            let response = try await client.get(id: checkout.id, lang: lang)
            await apply(response)
        } catch {
            handle(error, previous: previous, call: nil)
        }
    }

    /// Sends the last failed call again with the same idempotency key.
    public func retry() async {
        guard let call = failedCall else { return }
        failedCall = nil
        await perform(call)
    }

    /// Stops the checkout in the app, pointing at the checkout's fallback when it has one.
    public func fallBack(reason: String) {
        state = .fallback(checkout?.fallback, reason: reason)
    }

    private var isOnStep: Bool {
        if case .step = state { return true }
        return false
    }

    private var isFinished: Bool {
        switch state {
        case .finished, .fallback: return true
        default: return false
        }
    }

    private func perform(_ send: @escaping (BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse) async {
        let key = BookingContract.IdempotencyKey(rawValue: identifiers().uuidString.lowercased())
        await perform(Call(key: key, send: send))
    }

    private func perform(_ call: Call) async {
        let previous = state
        failedCall = nil
        state = .loading
        do {
            let response = try await call.send(call.key)
            await apply(response)
        } catch {
            handle(error, previous: previous, call: call)
        }
    }

    private func apply(_ response: BookingContract.CheckoutResponse) async {
        if response.isProcessing || response.checkout.status == .processing {
            await poll(response.checkout, interval: response.retryAfter)
        } else {
            apply(response.checkout)
        }
    }

    private func apply(_ checkout: BookingContract.Checkout) {
        self.checkout = checkout
        if checkout.status.value.isTerminal {
            state = .finished(checkout)
        } else if let action = checkout.nextAction {
            state = .action(action, checkout)
        } else if let step = checkout.currentStep {
            let layout = registry.layout(for: step)
            state = layout.isRenderable ? .step(step, checkout)
                : .fallback(checkout.fallback, reason: layout.unsupported.joined(separator: ", "))
        } else if checkout.status == .processing {
            state = .processing(checkout)
        } else {
            state = .fallback(checkout.fallback, reason: "status \(checkout.status.rawValue) without a step or action")
        }
    }

    private func poll(_ processing: BookingContract.Checkout, interval: TimeInterval?) async {
        checkout = processing
        state = .processing(processing)
        let deadline = clock().addingTimeInterval(Self.pollingLimit)
        var waited: TimeInterval = 0
        var nextInterval = interval ?? Self.defaultPollInterval
        while waited < Self.pollingLimit && clock() < deadline {
            do {
                try await sleep(nextInterval)
            } catch {
                break
            }
            waited += nextInterval
            do {
                let response = try await client.get(id: processing.id, lang: lang)
                if response.isProcessing || response.checkout.status == .processing {
                    checkout = response.checkout
                    nextInterval = response.retryAfter ?? Self.defaultPollInterval
                    continue
                }
                apply(response.checkout)
                return
            } catch let error as BookingContract.ContractError {
                if let replacement = error.data.checkout, replacement.status != .processing {
                    apply(replacement)
                    return
                }
            } catch {
                continue
            }
        }
        state = .processing(checkout ?? processing)
        onIssue?(.awaitingConfirmation)
    }

    private func handle(_ error: Error, previous: State, call: Call?) {
        guard let contractError = error as? BookingContract.ContractError else {
            failedCall = call
            state = previous
            onIssue?(.unavailable)
            return
        }
        let data = contractError.data
        switch contractError.code {
        case .validation:
            state = previous
            onIssue?(.fieldIssues(data.errors))
        case .stepMismatch, .priceChanged, .holdExpired, .soldOut, .notCancellable:
            if let replacement = data.checkout { apply(replacement) } else { state = previous }
            onIssue?(.conflict(contractError.code))
        case .paymentDeclined:
            if let replacement = data.checkout { apply(replacement) } else { state = previous }
            onIssue?(.paymentDeclined)
        case .supplierUnavailable, .inProgress:
            failedCall = call
            state = previous
            onIssue?(.unavailable)
        case .versionUnsupported, .idempotencyMismatch, .unknown:
            if data.retryable {
                failedCall = call
                state = previous
                onIssue?(.unavailable)
            } else {
                if let replacement = data.checkout { checkout = replacement }
                state = .fallback(data.checkout?.fallback ?? checkout?.fallback, reason: data.code.rawValue)
            }
        }
    }
}
