import UIKit
import WebKit
import TRPBookingKit

/// Loads a page in an in-app web view until it navigates to `returnURL`, then reports that URL.
/// Closing the screen first reports nil.
final class RedirectViewController: BookingBaseViewController, WKNavigationDelegate {

    private let pageURL: URL
    private let returnURL: String
    private let webView: WKWebView
    private var completion: ((String?) -> Void)?

    init(pageURL: URL, returnURL: String, theme: TRPBookingTheme, text: TRPBookingText, completion: @escaping (String?) -> Void) {
        self.pageURL = pageURL
        self.returnURL = returnURL
        self.completion = completion
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(theme: theme, text: text)
        title = text(.paymentTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        BookingWebScreen.embed(webView, in: self)
        webView.load(URLRequest(url: pageURL))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            finish(with: nil)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString, url.hasPrefix(returnURL) {
            decisionHandler(.cancel)
            finish(with: url)
        } else {
            decisionHandler(.allow)
        }
    }

    private func finish(with url: String?) {
        webView.stopLoading()
        let completion = completion
        self.completion = nil
        completion?(url)
    }
}

/// Runs `redirect`, and `three_ds` when its params carry a page and a return URL, in an in-app web view.
@MainActor
final class RedirectActionPresenter: NextActionPresenter {

    let type: String
    private let theme: TRPBookingTheme
    private let text: TRPBookingText

    init(type: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.type = type
        self.theme = theme
        self.text = text
    }

    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        guard let (page, returnURL) = Self.target(of: action), let pageURL = URL(string: page) else {
            return .unsupported(reason: action.typeRawValue)
        }
        let anchor = navigationController.topViewController
        let returned: String? = await withCheckedContinuation { continuation in
            let screen = RedirectViewController(pageURL: pageURL, returnURL: returnURL, theme: theme, text: text) {
                continuation.resume(returning: $0)
            }
            navigationController.pushViewController(screen, animated: true)
        }
        if let anchor, navigationController.viewControllers.contains(anchor), navigationController.topViewController !== anchor {
            navigationController.popToViewController(anchor, animated: true)
        }
        return .result(returned.map { .returned(url: $0) } ?? .status(.canceled))
    }

    private static func target(of action: BookingContract.NextAction) -> (page: String, returnURL: String)? {
        switch action {
        case .redirect(let payload):
            return (payload.params.url, payload.params.returnUrl)
        case .threeDS(let payload):
            guard let page = payload.params["url"]?.stringValue ?? payload.params["acsUrl"]?.stringValue,
                  let returnURL = payload.params["returnUrl"]?.stringValue else { return nil }
            return (page, returnURL)
        default:
            return nil
        }
    }
}
