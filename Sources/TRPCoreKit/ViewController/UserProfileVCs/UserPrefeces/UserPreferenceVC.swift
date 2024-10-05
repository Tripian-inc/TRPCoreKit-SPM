//
//  UserPreferenceVC.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 18.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import TRPUIKit
import TRPFoundationKit

protocol UserPreferenceVCDelegate:AnyObject {
    func userPreferanceVCSelectedUserPreferance(data: [Int])
}

public class UserPreferenceVC: TRPBaseUIViewController {
    
    public var selectedCells:[Int] = []
    private let viewModel: UserPreferenceViewModel
    private var tb: UITableView?
    
    weak var delegate: UserPreferenceVCDelegate?
    
    public init(viewModel: UserPreferenceViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        EvrAlertView.showAlert(contentText: "Changes will only effect future trips.", type: .info, showTime: 3)
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
        addApplyButton()
    }
    
    @objc override func applyButtonPressed() {
        viewModel.updateAnswer()
    }
}

extension UserPreferenceVC : UITableViewDataSource, UITableViewDelegate{
    
    func setupTableView(){
        let startY: CGFloat = 80
        let tableView = UITableView(frame: CGRect(x: 0, y: startY, width: view.frame.width, height: view.frame.height - startY - 70))
        tableView.register(cellClass: UITableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.reloadData()
        self.tb = tableView
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionCount()
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 8, width: 320, height: 20)
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = TRPColor.darkGrey
        label.textAlignment = .left
        label.text = self.tableView(tableView, titleForHeaderInSection: section)
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        headerView.addSubview(label)
        
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sectionTitle(section)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowInSection(section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
        let cellInfo = viewModel.cellInfo(indexPath)
        cell.textLabel?.text = cellInfo.name
        cell.accessoryType = viewModel.isItemSelected(id: cellInfo.id) ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.thin)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = viewModel.cellInfo(indexPath).id
        if viewModel.isItemSelected(id: id) {
            viewModel.itemIsDeselected(id: id)
        }else {
            viewModel.itemIsSelected(id: id)
        }
        tableView.reloadData()
        //SelectedSection?(selectedCells)
    }
    
}

extension UserPreferenceVC: UserPreferenceVMDelegate {
    
    public func userPreferenceVM(message: String) {
        EvrAlertView.showAlert(contentText: message, type: .success)
        self.navigationController?.popViewController(animated: true)
    }
    
    public func userPreferenceVM(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.tb?.reloadData()
        }
    }
    
    public func userPreferenceVM(showPreloader: Bool) {
        DispatchQueue.main.async {
            if showPreloader {
                self.loader?.show()
            }else {
                self.loader?.remove()
            }
        }
    }
    
    public func userPreferenceVM(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    public func userPreferanceVM(data: [Int]) {
        delegate?.userPreferanceVCSelectedUserPreferance(data: data)
    }
    
}
