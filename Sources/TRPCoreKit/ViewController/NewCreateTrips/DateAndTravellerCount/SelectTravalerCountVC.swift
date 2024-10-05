//
//  SelectTravalerCountVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 11.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

public protocol SelectTravalerCountVCDelegate: AnyObject {
    func travelersConfirmed(adultCount: Int, childrenCount: Int)
}
class SelectTravalerCountVC: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var adultLabel: UILabel!
    @IBOutlet weak var adultCountLabel: UILabel!
    @IBOutlet weak var childLabel: UILabel!
    @IBOutlet weak var childCountLabel: UILabel!
    @IBOutlet weak var applyBtn: TRPBlackButton!
    
    var viewModel: SelectTravelerCountVM!
    public weak var delegate: SelectTravalerCountVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        setupLabelFonts()
        setupTexts()
        viewModel.setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.containerView.transform = .identity
        }
    }
    
    @IBAction func adultCountPlusAction(_ sender: Any) {
        viewModel.increaseAdultCount()
    }
    
    @IBAction func adultCountMinusAction(_ sender: Any) {
        viewModel.decreaseAdultCount()
    }
    
    @IBAction func childCountPlusAction(_ sender: Any) {
        viewModel.increaseChildrenCount()
    }
    
    @IBAction func childCountMinusAction(_ sender: Any) {
        viewModel.decreaseChildrenCount()
    }
    
    @IBAction func applyBtnAction(_ sender: Any) {
        delegate?.travelersConfirmed(adultCount: viewModel.adultCount, childrenCount: viewModel.childrenCount)
        dismissView(completion: nil)
    }
    
    private func setupUI() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height + 100)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(bgPressed))
        view.addGestureRecognizer(gesture)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        containerView.layer.cornerRadius = 35
    }
    
    private func setupLabelFonts() {
        titleLabel.font = trpTheme.font.body3
        adultLabel.font = trpTheme.font.header2
        childLabel.font = trpTheme.font.header2
        adultCountLabel.font = trpTheme.font.header2
        childCountLabel.font = trpTheme.font.header2
    }
    
    private func setupTexts() {
        titleLabel.text = "Select number of adults and children".toLocalized()
        adultLabel.text = "Adults".toLocalized()
        childLabel.text = "Children".toLocalized()
        applyBtn.setTitle("Apply".toLocalized(), for: .normal)
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
    
    @objc func bgPressed() {
        dismissView(completion: nil)
    }
    
}

extension SelectTravalerCountVC: SelectTravelerCountVMDelegate {
    func adultCountChanged(count: String) {
        adultCountLabel.text = count
    }
    
    func childCountChanged(count: String) {
        childCountLabel.text = count
    }
    
}
