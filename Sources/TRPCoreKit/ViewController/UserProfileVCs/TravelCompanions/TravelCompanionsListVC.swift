//
//  TravelCompanionsListVC.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 17.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPUIKit
import TRPDataLayer


public protocol TravelCompanionsListVCDelegate: AnyObject {
    func openCompanionDetailView(parentVC: UIViewController, withCompanion: TRPCompanion)
    func openAddCompanionView(parentVC: UIViewController)
}

public class TravelCompanionsListVC: TRPBaseUIViewController {
    
    private let viewModel: TravelCompanionsVM
    fileprivate var tableView: EvrTableView?
    public weak var delegate: TravelCompanionsListVCDelegate?
    fileprivate var addBtn: UIBarButtonItem?
    fileprivate var isViewDidLoad: Bool = false //To check whether user has companion or not.
    
    init(viewModel: TravelCompanionsVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - LyfeCycles
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Travel Companions"
        isViewDidLoad = true
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
        setUpAddCompanion()
    }
    
}

// MARK: - TableView Delegates
extension TravelCompanionsListVC: UITableViewDataSource, UITableViewDelegate, EvrTableViewDelegate {
    
    public func evrTableViewLabelClicked() {
        addCompanionPressed()
    }
    
    fileprivate func setupTableView() {
        tableView = EvrTableView(frame: CGRect.zero)
        guard let tableView = tableView else {return}
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEmptyText(emptyText())
        tableView.emptyDelegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.layoutMargins = .zero
        tableView.register(cellClass: TravelCompanionsTableViewCell.self)
    }
    
    private func emptyText() -> NSMutableAttributedString{
        let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        let mainAttribute = NSMutableAttributedString(string: "List is empty.\n Create travel companions", attributes: typeAttributeStyle)
        let subTypeAttributeStyle = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        let subTypeAttribute = NSMutableAttributedString(string: " + ", attributes: subTypeAttributeStyle)
        mainAttribute.append(subTypeAttribute)
        return mainAttribute
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getDataCount()
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let selectedCompanion = viewModel.getItem(indexPath: indexPath)
            showRemoveAlert(companionName: selectedCompanion.name, companionId: selectedCompanion.id, indexPath: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: TravelCompanionsTableViewCell.self, forIndexPath: indexPath)
        let mData = viewModel.getItem(indexPath: indexPath)
        cell.textLabel?.text = mData.name == "" ? "(Name Not Specified)" : mData.name
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.getItem(indexPath: indexPath)
        delegate?.openCompanionDetailView(parentVC: self, withCompanion: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func openTravelCompanionDetail(){}
    
}

//MARK: - Functions
extension TravelCompanionsListVC{
    
    func setUpAddCompanion(){
        if let image = TRPImageController().getImage(inFramework: "plus_icon", inApp: TRPAppearanceSettings.Common.addButtonImage) {
            addBtn = UIBarButtonItem(image: image, style: UIBarButtonItem.Style.done, target: self, action: #selector(addCompanionPressed))
        }else {
            addBtn = UIBarButtonItem(title: "Add", style: UIBarButtonItem.Style.done, target: self, action: #selector(addCompanionPressed))
        }
        navigationItem.rightBarButtonItem = addBtn
    }
    
    fileprivate func showRemoveAlert(companionName: String?, companionId: Int, indexPath: IndexPath) {
        
        let text = "Are you sure you want to delete" + " \(companionName ?? "")?"
        let TitleString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : TRPColor.darkGrey])
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        optionMenu.setValue(TitleString, forKey: "attributedTitle")
      
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.viewModel.removeCompanion(companionId: companionId, indexPath: indexPath)
        }
        //Fixme:Mazinga "Cancel".toLocalized()
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let _ = self else {return}
        }
      
        cancelAction.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func removeCompanion(withIndex index: IndexPath){
        DispatchQueue.main.async {
            self.tableView!.deleteRows(at: [index], with: .fade)
            //Empty yapısı için eklenedi. silinecek
            self.tableView!.reloadData()
        }
    }
    
    func checkUserHasAnyCompanion(){
        if viewModel.getDataCount() == 0, isViewDidLoad{
            DispatchQueue.main.async {
                self.isViewDidLoad.toggle()
            }
        }
    }
    
    //MARK: - ObjC Functions
    @objc private func addCompanionPressed(){
        delegate?.openAddCompanionView(parentVC: self)
    }

}



//Mark: -ViewModel
extension TravelCompanionsListVC: TravelCompanionVMDelegate {
    func travelCompanionVM(showPreloader: Bool) {
        guard let loader = loader else {return}
        DispatchQueue.main.async {
            if showPreloader {
                loader.show()
            }else {
                loader.remove()
            }
        }
    }
    
    func travelCompanionVM(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    func travelCompanionVM(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.checkUserHasAnyCompanion()
        }
    }
    
    func companionRemoved(indexPath: IndexPath) {
        removeCompanion(withIndex: indexPath)
    }
}
