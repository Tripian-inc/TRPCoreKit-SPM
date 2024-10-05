//
//  PersonalInfoViewController.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-05-14.
//

import UIKit


class PersonalInfoViewController: TRPBaseUIViewController {
    
    var viewModel: PersonalInfoViewModel!
    
    @IBOutlet weak var firstNameTF: TRPTF!
    @IBOutlet weak var lastNameTF: TRPTF!
    @IBOutlet weak var emailTF: TRPTF!
    @IBOutlet weak var ageTF: TRPTF!
    @IBOutlet weak var birthDayTF: TRPTF!
    @IBOutlet weak var changePasswordLbl: UILabel!
    @IBOutlet weak var updateBtn: TRPBlackButton!
    @IBOutlet weak var questionsTableView: UITableView!
    @IBOutlet weak var changePasswordView: UIView!
    @IBOutlet weak var deleteUserBtn: UIButton!
    
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        navigationItem.title = "Profile"
        addBackButton(position: .left)
        viewModel.start()
        setupView()
        setupTableView()
        setToolbarForBirthTF()
    }

    @IBAction func updateBtnPressed(_ sender: UIButton) {
//        let age = Int(ageTF.text ?? "0") ?? 0
        viewModel.save(firstName: firstNameTF.text ?? "", lastName: lastNameTF.text ?? "", dateOfBirth: birthDayTF.text ?? "")
    }
    
    @IBAction func changePasswordBtnPressed(_ sender: Any) {
        self.viewModel.openChangePassword()
    }
    
    @IBAction func deleteUserBtnPressed(_ sender: Any) {
        self.deleteAccount()
    }
}

extension PersonalInfoViewController {
    private func setupView() {
        emailTF.isEnabled = false
        emailTF.textColor = trpTheme.color.tripianTextPrimary.withAlphaComponent(0.5)
        
        changePasswordLbl.font = trpTheme.font.body2
        changePasswordLbl.textColor = trpTheme.color.tripianTextPrimary
        
        updateBtn.setTitle("Update", for: .normal)
        
        deleteUserBtn.setTitle("Delete account", for: .normal)
        deleteUserBtn.setTitleColor(trpTheme.color.tripianPrimary, for: .normal)
        deleteUserBtn.titleLabel?.font = trpTheme.font.header2
        
        edgesForExtendedLayout = []
        
        if TRPUserPersistent.isSocialLogin {
            changePasswordView.removeFromSuperview()
        }
    }

    private func setToolbarForBirthTF() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolBar.setItems([doneBtn], animated: false)
        
        birthDayTF.inputAccessoryView = toolBar
        setCalendarForTF()
    }

    private func setCalendarForTF() {
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerValueChanded), for: .valueChanged)
        datePicker.maximumDate = Date()
        birthDayTF.inputView = datePicker
    }
    
    @objc func calendarDoneBtn() {
        let date = datePicker.date.toStringWithoutTimeZone(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        birthDayTF.text = date
//        viewModel.birthDay = date
        view.endEditing(true)
    }
    
    @objc func datePickerValueChanded() {
        let date = datePicker.date.toStringWithoutTimeZone(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        birthDayTF.text = date
//        viewModel.birthDay = date
    }
    
    
    private func deleteAccount() {
        showConfirmAlert(title: "", message: "Are you sure you want to delete your account?".toLocalized(), confirmTitle: "Delete", cancelTitle: "Cancel", btnConfirmAction: {
            self.viewModel.deleteAccount()
            
        })
    }
}

extension PersonalInfoViewController: PersonalInfoViewModelDelegate {
    func handleViewModelOutput(_ output: PersonalInfoViewModelOutput) {
        switch output {
        case .showError(let error):
            EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
        case .showLoading(let status):
            showLoader(status)
        case .updatePersonalInfo(let person):
            firstNameTF.text = person.name
            lastNameTF.text = person.lastName
            emailTF.text = person.email
//            ageTF.text = person.dateOfBirth
            birthDayTF.text = person.dateOfBirth
        case .showMessage(let message):
            showMessage(message, type: .success)
        case .reload:
            questionsTableView.reloadData()
        }
    }
    
}

extension PersonalInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    fileprivate func setupTableView() {
        questionsTableView.tableFooterView = UIView(frame: .zero)
        questionsTableView.rowHeight = UITableView.automaticDimension
        questionsTableView.estimatedRowHeight = 80
        questionsTableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionsTableViewCell", for: indexPath) as! QuestionsTableViewCell
        let questionsVM = QuestionsVM(questionMenu: viewModel.getItem(indexPath: indexPath))
        questionsVM.delegate = self
        questionsVM.selectedItemIds = viewModel.selectedItemIds
        cell.viewModel = questionsVM
        cell.configure()
        cell.selectionStyle = .none
        return cell
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension PersonalInfoViewController: QuestionsVMDelegate {
    func itemSelected(id: Int) {
        viewModel.itemIsSelected(id: id)
    }
    
    func itemDeselected(id: Int) {
        viewModel.itemIsDeselected(id: id)
    }
    
    
}

class TRPTF: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        borderStyle = .none
        backgroundColor = trpTheme.color.extraSub
        layer.borderWidth = 1
        layer.borderColor = trpTheme.color.extraShadow.cgColor
        layer.cornerRadius = 15
        setLeftPaddingPoints(16)
        
        font = trpTheme.font.body2
        textColor = trpTheme.color.tripianBlack
    }
}
