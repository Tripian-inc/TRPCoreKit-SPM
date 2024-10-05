//
//  ExperienceRequirementFieldViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-01.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPProvider

protocol ExperienceRequirementFieldVCDelegate: AnyObject  {
    func experienceRequirementFieldOpenBillingVC(_ navigationController: UINavigationController?, viewController: UIViewController)

}
class ExperienceRequirementFieldViewController: TRPBaseUIViewController {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var languaveView: RequirementFieldSubView?
    var hotelView: RequirementFieldSubView?
    var requirementView: RequirementFieldSubView?
    private var keyboardController: ScrollViewKeyboardController?
    
    weak var delegate: ExperienceRequirementFieldVCDelegate?
    let viewModel: ExperienceRequirementFieldViewModel
    
    init(viewModel: ExperienceRequirementFieldViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Activity Details"
//        navigationController?.navigationBar.prefersLargeTitles = true
        keyboardController = ScrollViewKeyboardController(scrollView: scrollView)
    }
    
    public override func setupViews() {
        super.setupViews()
        addViews()
        addApplyButton()
        applyButton.setTitle("Next", for: .normal)
    }
    
    override func applyButtonPressed() {
        
        let lang = languaveView?.getSelectedValue()
        let hotel = hotelView?.getSelectedValue()
        let supplier = requirementView?.getSelectedValue()
        let isValid = viewModel.isInputValuesValid(language: lang,
                                                   hotel: hotel,
                                                   supplier: supplier)
        
        if !isValid {
            print("Gerekli Parametreler girilmedi")
            return
        }
        
        viewModel.setBookingParameters(language: lang,
                                       hotel: hotel,
                                       supplier: supplier)
        viewModel.makeBooking()
        //Todo: Boşluk denetlenecek
        
    }
}

extension ExperienceRequirementFieldViewController {
    private func addViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
 
    
    private func openLanguageAction() {
        let alert = UIAlertController(title: "Language".toLocalized(), message: "".toLocalized(), preferredStyle: .actionSheet)
        let cancelBtn = UIAlertAction(title: "Cancel".toLocalized(), style: .cancel, handler: { (action) in
           // self.delegate?.trpTripCreateCoordinaterCleanCreateTrip()
        })
        
        let actionButtonHandler = {(lang: String, type: String) in
            { (action: UIAlertAction!) -> Void in
                if let langView = self.languaveView  {
                    langView.selectedContent = " \(lang.readableLanguage())"
                    self.viewModel.setSelectedLanugage(language: lang, type: type)
                }
            }
        }
        
        if let lang = viewModel.language {
            
            lang.languageAudio.forEach { audi in
                let content = "\(audi.readableLanguage()) (Audio)"
                let button = UIAlertAction(title: content, style: .default, handler: actionButtonHandler(audi, "language_audio"))
                alert.addAction(button)
            }
            
            lang.languageBooklet.forEach { booklet in
                let content = "\(booklet.readableLanguage()) (Booklet)"
                let button = UIAlertAction(title: content, style: .default, handler: actionButtonHandler(booklet, "language_booklet"))
                alert.addAction(button)
            }
            
            lang.languageLive.forEach { live in
                let content = "\(live.readableLanguage()) (Live)"
                let button = UIAlertAction(title: content, style: .default, handler: actionButtonHandler(live, "language_live"))
                alert.addAction(button)
            }
        }
        
        alert.addAction(cancelBtn)
        present(alert, animated: true, completion: nil)
    }
    
}

extension ExperienceRequirementFieldViewController: ExperienceRequirementFieldViewModelDelegate {
    
    
    
    override func viewModel(dataLoaded: Bool) {
        
        if let language = viewModel.languageModel {
            let action = language.type == .bottomAction ? true : false
            languaveView = RequirementFieldSubView(title: language.title, subTitle: language.subTitle, placeHolder: language.placeHolder, numberOfLine: 0, openAction: action)
            languaveView!.selectedAction = {
                self.openLanguageAction()
            }
            mainStackView.addArrangedSubview(languaveView!)
        }
    
        if let hotel = viewModel.hotelModel {
            hotelView = RequirementFieldSubView(title: hotel.title, subTitle: nil, placeHolder: hotel.placeHolder, numberOfLine: 2)
            mainStackView.addArrangedSubview(hotelView!)
        }

        if let required = viewModel.requiredInfoModel {
            requirementView = RequirementFieldSubView(title: required.title, subTitle: required.subTitle, placeHolder: required.placeHolder, numberOfLine: 2)
            mainStackView.addArrangedSubview(requirementView!)
        }
        
    }
    
    
    func experienceRequirementFieldBookingCompleted(_ booking: GYGBookings?) {
        delegate?.experienceRequirementFieldOpenBillingVC(self.navigationController, viewController: self)
    }
}


