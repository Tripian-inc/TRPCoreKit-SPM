//
//  ProfileVC.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//
import UIKit
import TRPUIKit
import TRPRestKit

protocol ProfileVCDelegate: AnyObject {
    func profileVCOpenView(selectedItem: ProfileMenu)
    func profileVCSignOut()
    func profileVCUserPreferances(data: [Int])
}

class ProfileVC: TRPBaseUIViewController {
    
    private let viewModel: ProfileVM
    fileprivate var tableView: UITableView?
    public weak var delegate: ProfileVCDelegate?
    fileprivate let cellNames:[(className: UITableViewCell.Type, value: String)] = [(className: ProfileNormalCell.self, value: "ProfileNormalCell"),
                                                                                    (className: ProfileLabelCell.self, value: "ProfileLabelCell")]

    init(viewModel: ProfileVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        hideKeyboardWhenTappedAround()
    }
    
    override func setupViews() {
        super.setupViews()
        setupTableView()
    }
    
    
}

// MARK: - TableView
extension ProfileVC: UITableViewDataSource, UITableViewDelegate {
    
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
        tableView.register(cellClass: ProfileLabelCell.self)
        tableView.register(cellClass: ProfileNormalCell.self)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getDataCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mData = viewModel.getItem(indexPath: indexPath)
        if mData.menuType == .label{
            return createLabelCell(tableView, indexPath: indexPath, model: mData)
        }
        return createDefaultCell(tableView, indexPath: indexPath, model: mData)
    }
 
    private func createLabelCell(_ tableView: UITableView, indexPath: IndexPath, model: ProfileMenu) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ProfileLabelCell.self, forIndexPath: indexPath)
        cell.label.text = viewModel.getUserInfo("email")//TODO: Buraya Kullanici Adi Konulacak
        cell.labelPlaceholder.text = model.name // First Name
        cell.selectionStyle = .none
        return cell
    }
    
    private func createDefaultCell(_ tableView: UITableView, indexPath: IndexPath, model: ProfileMenu) -> UITableViewCell {
        let cellDefault = tableView.dequeue(cellClass: ProfileNormalCell.self, forIndexPath: indexPath)
        cellDefault.titleLabel.text = model.name
        if let img = TRPImageController().getImage(inFramework: model.icon, inApp: TRPAppearanceSettings.Common.addButtonImage) {
            cellDefault.iconImage.image = img
        }
        return cellDefault
    }
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let mData = viewModel.getItem(indexPath: indexPath)
        if mData.menuType == .textField || mData.menuType == .label {
            return 120
        }
        return 90
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.getItem(indexPath: indexPath)
        switch item.id {
        case 4: // password ID
            showChangePasswordAlert()
            break
        case 6: // sign out ID
            signOutTapped()
            break
        case 5: // helpDesk ID
            helpDeskTapped()
            break
        case 7:
            showAppVersion()
        default:
            break
        }
        delegate?.profileVCOpenView(selectedItem: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ProfileVC {
    func showAppVersion() {
        let alertController = UIAlertController(title: nil , message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        for version in viewModel.appInfo {
            let action = UIAlertAction(title: "\(version.key) - \(version.value)", style: UIAlertAction.Style.default, handler: nil)
            alertController.addAction(action)
        }
        let action = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
}

//MARK: - Functions
extension ProfileVC {
    
    fileprivate func signOutTapped(){
        showSignOutAlert()
    }
    
    fileprivate func showSignOutAlert(){
        let signOutMenu = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let titleS = "Are you sure you want to sign out?"//.toLocalized()
        let TitleString = NSAttributedString(string: titleS, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : TRPColor.darkGrey])
        signOutMenu.setValue(TitleString, forKey: "attributedTitle")
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.signOut()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {[weak self] _ in
            guard let _ = self else {return}
        }
        signOutMenu.addAction(yesAction)
        signOutMenu.addAction(cancelAction)
        self.present(signOutMenu, animated: true, completion: nil)
    }
    
    fileprivate func signOut(){
        dismiss(animated: true, completion: nil)
        self.delegate?.profileVCSignOut()
    }
    
    fileprivate func helpDeskTapped(){
        guard let url = URL(string: "https://tripian.zendesk.com/hc/en-us") else { return }
        UIApplication.shared.open(url)
    }
    
    fileprivate func showChangePasswordAlert() {
        let alertController = UIAlertController(title: "Please Enter Your New Password", message: "", preferredStyle: UIAlertController.Style.alert)
        let titleS = "Please Enter Your New Password"
        let TitleString = NSAttributedString(string: titleS, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : TRPColor.darkGrey])
        alertController.setValue(TitleString, forKey: "attributedTitle")
        alertController.addTextField { (textField : UITextField!) -> Void in
            
            textField.placeholder = "Your New Password"
            textField.isSecureTextEntry = true
            textField.textColor = TRPColor.darkGrey
        }
        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let passwordTextField = alertController.textFields![0] as UITextField
            if let text = passwordTextField.text{
                self.saveOnlyPassword(text)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {
            (action : UIAlertAction!) -> Void in })
        
        cancelAction.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func saveOnlyPassword(_ pass:String){
        if loader != nil {
            loader!.show()
        }
        viewModel.updatePassword(pass: pass)
    }
}


extension ProfileVC: ProfileVMDelegate {
    func profileVM(message: String) {
        EvrAlertView.showAlert(contentText: message, type: .info)
    }
    
    func profileVM(showPreloader: Bool) {
        guard let loader = loader else {return}
        DispatchQueue.main.async {
            if showPreloader {
                loader.show()
            }else {
                loader.remove()
            }
        }
    }
    
    func profileVM(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    func profileVM(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    func profileVMUserPreferences(_ data: [Int]) {
        //Fixme:Mazinga
    }
    
    
}

