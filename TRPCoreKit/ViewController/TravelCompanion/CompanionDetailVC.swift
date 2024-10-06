//
//  CompanionDetailVC.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

import UIKit


public protocol CompanionDetailVCDelegate: AnyObject {
    func companionDetailVCAdded(_ companion: TRPCompanion)
    func companionDetailVCUpdated()
}

public enum CompanionDetailType{
    case addCompanion, updateCompanion
}

@objc(SPMCompanionDetailVC)
public class CompanionDetailVC: TRPBaseUIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var applyBtn: TRPBlackButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: EvrTableView!
    @IBOutlet weak var descLabel: UILabel!
    //MARK: - Variables
    public var viewModel: CompanionDetailVM!
    public weak var delegate: CompanionDetailVCDelegate?
    
    fileprivate var activeTextField = UITextField()
    public var inModal:Bool? = true
    private var isPostCompleted = true
    fileprivate var closeBtn: UIBarButtonItem?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
        setupUI()
        titleLabel.font = trpTheme.font.header2
        titleLabel.textColor = trpTheme.color.tripianBlack
        descLabel.font = trpTheme.font.body1
        descLabel.textColor = trpTheme.color.tripianBlack
    }
    
    private func setupUI() {
        applyBtn.backgroundColor = trpTheme.color.tripianPrimary
//        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height + 100)
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(bgPressed))
//        view.addGestureRecognizer(gesture)
//        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
//        containerView.layer.cornerRadius = 35
    }
    
    
//    public override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
//            self?.containerView.transform = .identity
//        }
//    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewModel.isUpdateType {
            titleLabel.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.travelerInfo.companion.title")
            descLabel.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.travelerInfo.companion.description")
            applyBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.travelerInfo.companion.submit"), for: .normal)
            openKeyboard()
        } else {
            titleLabel.text = "\(viewModel.getCompanionName())"
            applyBtn.setTitle(TRPLanguagesController.shared.getApplyBtnText(), for: .normal)
            viewModel.setForUpdate()
        }
    }
    
    @IBAction func applyButtonAction(_ sender: Any) {
        saveChanges()
    }
    
//    public func dismissView(completion: ((_ status: Bool) -> Void)?) {
//        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
//            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
//        } completion: { _ in
//            self.dismiss(animated: false) {
//                completion?(true)
//            }
//        }
//    }
    
//    @objc func bgPressed() {
//        dismissView(completion: nil)
//    }
}

// MARK: - TableView
extension CompanionDetailVC: UITableViewDataSource, UITableViewDelegate {
    
    fileprivate func setupTableView() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 50;
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionCount()
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "CreateTripTextFieldHeaderCell") as? CreateTripTextFieldHeaderCell else {return UIView() }
        let title = viewModel.getSectionTitle(section: section)
        headerView.titleLabel.text = title
        
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCellCount(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = viewModel.getCellModel(at: indexPath)
        let sectionType = cellModel.menuType
        
        switch sectionType {
        case .textField:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CompanionTextFieldCell", for: indexPath) as! CompanionTextFieldCell
            if let text = cellModel.value, text.count > 0{
                cell.textField.text = text
            }else{
                cell.textField.setPlaceholder(text: cellModel.name)
            }
            
            cell.textField.tag = cellModel.menuId
            cell.textField.keyboardType = viewModel.isNumberEditable(menuId: cellModel.menuId) ? UIKeyboardType.numberPad : .default
            cell.textField.returnKeyType = .next
            cell.cellDelegate = self
            cell.selectionStyle = .none
            return cell
        case .checklist:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CompanionQuestionAnswersCell", for: indexPath) as! CompanionQuestionAnswersCell
            let companionQuestionAnswersVM = CompanionQuestionAnswersVM(companionDetailMenu: cellModel)
            companionQuestionAnswersVM.delegate = self
            companionQuestionAnswersVM.selectedItemIds = viewModel.getSelectedItemIds(menuId: cellModel.menuId)
            cell.viewModel = companionQuestionAnswersVM
            cell.configure()
            cell.selectionStyle = .none
            return cell
        default:
            let cellDefault = tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
            
            cellDefault.textLabel?.text = cellModel.name
            cellDefault.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.thin)
            return cellDefault
        }
    }
    
}

//MARK: - Functions
extension CompanionDetailVC{
    
    public  func saveChanges() {
        guard !viewModel.getCompanionName().isEmpty else {
            companionDetailShowMessage(TRPLanguagesController.shared.getLanguageValue(for: "name_is_required"))
            return
        }
        guard let _ = viewModel.getSelectedTitle() else {
            companionDetailShowMessage(TRPLanguagesController.shared.getLanguageValue(for: "select_title_for_your_companion"))
            return
        }
        viewModel.saveChanges()
    }
    
    @objc func closeBtnPressed() {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - TextFieldCellProtocol
extension CompanionDetailVC:CompanionTextFieldCellProtocol{
    
    public func setTextFieldVal(text: String, val: Int) {
        if val == 1 {
            viewModel.setCompanionName(name: text)
        }else{
            if let mAge = Int(text) {
                viewModel.setCompanionAge(age: mAge)
            }
        }
    }
    
}


//MARK: - ViewModel
extension CompanionDetailVC: CompanionDetailVMDelegate {
    public func companionsDetaionVM(showPreloader: Bool) {
        guard let loader = loader else {return}
        DispatchQueue.main.async {
            if showPreloader {
                loader.show()
            }else {
                loader.remove()
            }
        }
    }
    
    public func companionsDetaionVM(error: Error) {
        isPostCompleted = true
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    public func companionsDetaionVM(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    public func companionsDetailCompanionAdded(_ companion: TRPCompanion){
        isPostCompleted = true
        DispatchQueue.main.async {
            self.delegate?.companionDetailVCAdded(companion)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func companionsDetailCompanionUpdated() {
        isPostCompleted = true
        DispatchQueue.main.async {
            self.delegate?.companionDetailVCUpdated()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func companionDetailShowMessage(_ message: String) {
        EvrAlertView.showAlert(contentText: message, type: .error)
    }
    
    
}


extension CompanionDetailVC: CompanionQuestionAnswersVMDelegate {
    public func itemSelected(id: Int, menuId: Int) {
        viewModel.itemIsSelected(id: id, menuId: menuId)
    }
    
    public func itemDeselected(id: Int, menuId: Int) {
        viewModel.itemIsDeselected(id: id, menuId: menuId)
    }
    
    
}


//MARK: - Keyboard Functions
extension CompanionDetailVC {
    func openKeyboard(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            //Cell in icine becomefirst responder deyince table view yuklenmeden geliyor orada view acilirken cirkin duruyor, burada daha dogru
            self.activeTextField.becomeFirstResponder()
        }
    }
}
