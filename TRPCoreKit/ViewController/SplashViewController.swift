//
//  SplasViewController.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.08.2025.
//

import UIKit

protocol SplashViewControllerDelegate: AnyObject {
    func datasFetchCompleted()
    func datasFetchFailed()
}

class SplashViewController: TRPBaseUIViewController {
    
    var delegate: SplashViewControllerDelegate?
    var uniqueId: String? = nil
    var email: String? = nil
    var password: String? = nil

    private var loginSuccess: Bool = false
    private var languagesFetched: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavigationBar()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        fetchLanguages()
        TRPFonts.registerAll()
//        TRPFonts.debugRegisterAndReport()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showLottieLoader()
    }

    private func showLottieLoader() {
        // Splash → first GetTimeline are part of the same "opening the app" moment,
        // so use the same localized message as the timeline initial fetch — the
        // window-attached loader carries through without a flicker between them.
        let message = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingYourItineraryPlan)
        viewModel(showLottie: .fullScreen, textMode: .single(message))
    }

    private func hideLottieLoader() {
        viewModel(hideLottie: .fullScreen)
    }

    func start() {
        if let uniqueId {
            startForLightLogin()
            return
        }
        if let email {
            if let password {
                startWithEmailAndPassword(email, password)
                return
            }
            startWithEmail(email)
            return
        }
        startForGuest()
    }

    private func startForLightLogin() {
        TRPLoginHelper.shared.lightLogin(uniqueId: uniqueId!) { [weak self] (result) in
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.hideLottieLoader()
                self?.delegate?.datasFetchFailed()
            }
        }
    }

    private func startForGuest() {
        TRPLoginHelper.shared.guestLogin { [weak self] (result) in
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.hideLottieLoader()
                self?.delegate?.datasFetchFailed()
            }
        }
    }

    public func startWithEmail(_ email: String) {
        TRPLoginHelper.shared.login(email: email) { [weak self] (result) in
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.hideLottieLoader()
                self?.delegate?.datasFetchFailed()
            }
        }
    }

    public func startWithEmailAndPassword(_ email: String, _ password: String) {
        TRPLoginHelper.shared.login(email: email, password: password) { [weak self] (result) in
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.hideLottieLoader()
                self?.delegate?.datasFetchFailed()
            }
        }
    }
    
    private func fetchLanguages() {
        TRPLanguagesController.shared.getLanguages() { [weak self] result in
            self?.languagesFetched = true
            self?.checkAllDatasFetched()
        }
    }
    
    private func checkAllDatasFetched() {
        guard loginSuccess, languagesFetched else { return }

        // Fetch cities in background after login success (non-blocking)
        TRPCityCache.shared.fetchCitiesIfNeeded()

        // Don't hide here — the Lottie loader is window-attached, so the next VC's
        // `showOnWindow(...)` simply refreshes the text mode without a flicker.
        delegate?.datasFetchCompleted()
        navigationController?.popViewController(animated: false)
    }

}
