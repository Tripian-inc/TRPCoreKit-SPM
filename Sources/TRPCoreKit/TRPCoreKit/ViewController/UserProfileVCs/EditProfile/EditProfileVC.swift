//
//  EditProfileVC.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit


public protocol EditProfileVCDelegate: AnyObject {
    func editProfileVCOpenView(selectedItem: ProfileMenu)
    func editProfileVCUserProfile(data: [Int])
}

public class EditProfileVC: TRPBaseUIViewController {
    
    
    private let viewModel: EditProfileVM
    fileprivate var tableView: UITableView?
    public weak var delegate: EditProfileVCDelegate?
    fileprivate let cellNames:[(className: UITableViewCell.Type, value: String)] = [(className: ProfileTitleCell.self, value: "ProfileTitleCell"), (className: ProfileNormalCell.self, value: "ProfileNormalCell"),(className: ProfileTextFieldCell.self, value: "ProfileTextFieldCell"),(className: ProfileLabelCell.self, value: "ProfileLabelCell")]
    
    var showSaveChanges: Bool = false
    fileprivate var firstName: String?, lastName: String?
    fileprivate var inSave:Bool = false
    fileprivate var saveBtn: UIBarButtonItem?
    fileprivate var dateOfBirth: String?
    
    init(viewModel: EditProfileVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        title = "Edit Profile"
        setupTableView()
        addApplyButton()
    }

    override func applyButtonPressed() {
        if !inSave{
            inSave = true
            viewModel.updateUserInfo(firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth)
        }
    }
}

// MARK: - TableView
extension EditProfileVC: UITableViewDataSource, UITableViewDelegate {
    
    fileprivate func setupTableView() {
        tableView = UITableView(frame: CGRect.zero)
        guard let tableView = tableView else {return}
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.layoutMargins = .zero
        tableView.register(cellClass: ProfileTextFieldCell.self)
        tableView.register(cellClass: ProfileNormalCell.self)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getDataCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mData = viewModel.getItem(indexPath: indexPath)
        if mData.menuType == .textField{
            return createTextFieldCell(tableView, indexPath: indexPath, model: mData)
        }
        return createDefaultCell(tableView, indexPath: indexPath, model: mData)
    }
    
    private func createTextFieldCell(_ tableView: UITableView, indexPath: IndexPath, model: ProfileMenu) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ProfileTextFieldCell.self, forIndexPath: indexPath)
        let text = viewModel.getUserInfo(model.id)
        cell.limitWith99 = false
        if text.count > 0{
            cell.textField.text = text
        }else{
            cell.textField.placeholder = model.name
        }
        cell.textFieldPlaceholderLabel.text = model.name
        cell.textField.tag = model.id
        if model.id == 3{
            cell.textField.keyboardType = UIKeyboardType.numberPad
            cell.textField.returnKeyType = .done
            cell.limitWith99 = true
        }else{
            cell.textField.returnKeyType = .next
        }
        cell.cellDelegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    private func createDefaultCell(_ tableView: UITableView, indexPath: IndexPath, model: ProfileMenu) -> UITableViewCell {
        let cellDefault = tableView.dequeue(cellClass: ProfileNormalCell.self, forIndexPath: indexPath)
        cellDefault.titleLabel.text = model.name
        cellDefault.accessoryType = .disclosureIndicator
        cellDefault.selectionStyle = .gray
        return cellDefault
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.getItem(indexPath: indexPath)
        delegate?.editProfileVCOpenView(selectedItem: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
}


extension EditProfileVC: EditProfileVMDelegate {
    
    func editProfileVM(showPreloader: Bool) {
        guard let loader = loader else {return}
        DispatchQueue.main.async {
            if showPreloader {
                loader.show()
            }else {
                loader.remove()
            }
        }
    }
    
    func editProfileVM(error: Error) {
        inSave = false
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    func editProfileVM(dataLoaded: Bool) {
        inSave = false
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    func editProfileVM(message: String) {
        EvrAlertView.showAlert(contentText: message, type: .info)
    }
    
    func editProfileVMUserProfile(data: [Int]) {
        self.delegate?.editProfileVCUserProfile(data: data)
    }
    
}

extension EditProfileVC : ProfileTextFieldCellProtocol{
    
    func saveChanges() {
        applyButtonPressed()
    }
    
    func didTapCell() {
        showSaveChangesButton()
    }
    
    func setTextFieldVal(text: String, val: Int) {
        switch val {
        case 1:
            firstName = text
            break
        case 2:
            lastName = text
            break
        case 3:
            dateOfBirth = text
//            if let mAge = Int(text) {
//                dateOfBirth = text
//            }
            break
        default:
            break
        }
    }
    
    func showSaveChangesButton(){
        showSaveChanges = true
    }
}
