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
    var forGuest: Bool = true
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
        self.viewModel(showPreloader: true)
    }
    
    func start() {
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
    
    private func startForGuest() {
        TRPLoginHelper.shared.guestLogin { [weak self] (result) in
            self?.viewModel(showPreloader: false)
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.delegate?.datasFetchFailed()
            }
        }
    }
    
    public func startWithEmail(_ email: String) {
        TRPLoginHelper.shared.login(email: email) { [weak self] (result) in
            self?.viewModel(showPreloader: false)
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
                self?.delegate?.datasFetchFailed()
            }
        }
    }
    
    public func startWithEmailAndPassword(_ email: String, _ password: String) {
        TRPLoginHelper.shared.login(email: email, password: password) { [weak self] (result) in
            self?.viewModel(showPreloader: false)
            if result {
                self?.loginSuccess = true
                self?.checkAllDatasFetched()
            } else {
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
        delegate?.datasFetchCompleted()
        navigationController?.popViewController(animated: false)
    }

}
