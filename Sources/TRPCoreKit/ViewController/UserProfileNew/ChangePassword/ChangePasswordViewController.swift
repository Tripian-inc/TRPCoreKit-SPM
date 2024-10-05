//
//  ChangePasswordViewController.swift
//  Wiserr
//
//  Created by Cem Çaygöz on 6.08.2021.
//

import UIKit

class ChangePasswordViewController: TRPBaseUIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordTF: TRPTF!
    @IBOutlet weak var confirmPasswordTF: TRPTF!
    @IBOutlet weak var applyBtn: TRPBlackButton!
    
    var viewModel: ChangePasswordViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        addObserver()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.containerView.transform = .identity
        }
    }
    
    private func setupView() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height + 100)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        containerView.layer.cornerRadius = 35
        
        titleLabel.font = trpTheme.font.header2
        titleLabel.textColor = trpTheme.color.tripianBlack
        titleLabel.text = "Change Password"
        applyBtn.setTitle("Update", for: .normal)
        
        setupTextFieldUI(textField: passwordTF)
        passwordTF.placeholder = "Password"
        passwordTF.tag = 0
        
        setupTextFieldUI(textField: confirmPasswordTF)
        confirmPasswordTF.placeholder = "Password(Confirm)"
        confirmPasswordTF.tag = 1
    }
    
    private func setupTextFieldUI(textField: TRPTF) {
        textField.backgroundColor = trpTheme.color.extraSub
        textField.layer.cornerRadius = 15.0
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = trpTheme.color.extraShadow.cgColor
        textField.borderStyle = .none
        textField.delegate = self
    }
    
    private func addObserver() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification?) {
        if let keyboardSize = (notification?.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.origin.y - keyboardSize.height)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification?) {
        UIView.animate(withDuration: 0.4) {
            self.containerView.transform = .identity
        }
    }
    
    public func dismissView(completion: ((_ status: Bool) -> Void)?) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
        } completion: { _ in
            self.dismiss(animated: false) {
                completion?(true)
            }
        }
    }
    
    @IBAction func applyBtnPressed(_ sender: Any) {
        setEditing(true, animated: true)
        viewModel.save(password: passwordTF.text ?? "", confirmPassword: confirmPasswordTF.text ?? "")
    }
    @IBAction func closeBtnPressed(_ sender: Any) {
        dismissView(completion: nil)
    }
    
}

extension ChangePasswordViewController: ChangePasswordViewModelDelegate {
    func handleViewModelOutput(_ output: ChangePasswordViewModelOutput) {
        switch output {
        case .showError(let error):
            showError(error)
        case .showLoading(let status):
            showLoader(status)
        case .updatedPassword:
            dismissView(completion: nil)
        case .showMessage(let message):
            showMessage(message, type: .success)
        case .showWarning(let message):
            showMessage(message, type: .error)
        }
    }
    
}

extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            confirmPasswordTF.becomeFirstResponder()
        } else if textField.tag == 1{
            view.endEditing(true)
        }
        return true
    }
}
