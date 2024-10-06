//
//  StayAddressVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 30.01.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit



public protocol StayAddressVCDelegate:AnyObject {
    func stayAddressContinuePressed(mustClean: Bool)
    func stayAddressSelectedPlace(stayAddress: TRPAccommodation)
}

@objc(TRPStayAddressVC)
class StayAddressVC: TRPBaseUIViewController {
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: EvrTableView!
    
    var viewModel: StayAddressViewModel!
    public weak var delegate: StayAddressVCDelegate?
    fileprivate var requestWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.getMainTitle()
        
        addBackButton(position: .left)
        searchBar.text = viewModel.getDefaultSearchText()
    }
    
    override func setupViews() {
        super.setupViews()
        setupTableView()
        setupSearchBar()
        setupSearchView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        searchBar.becomeFirstResponder()
    }
    
    func setupSearchView() {
        searchView.backgroundColor = UIColor.white
        searchView.layer.cornerRadius = 30
        searchView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        searchView.layer.shadowColor = UIColor.lightGray.cgColor
        searchView.layer.shadowOffset = CGSize(width: 0, height: 4)
        searchView.layer.shadowOpacity = 0.3
        searchView.layer.shadowRadius = 5
    }
}

extension StayAddressVC: UISearchBarDelegate{
    
    func setupSearchBar() {
        //To remove borders
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = trpTheme.color.extraBG
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = trpTheme.color.extraSub
        }
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        requestWorkItem?.cancel()
        let newRequest = DispatchWorkItem { [weak self] in
            if let currentVM = self?.viewModel {
                currentVM.searchAddress(text: searchText)
            }
        }
        
        requestWorkItem = newRequest
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: newRequest)
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
//        viewModel.clearData()
    }
}

extension StayAddressVC: UITableViewDelegate, UITableViewDataSource {

    fileprivate func setupTableView() {
        tableView!.emptyTextStartY = 120
        tableView!.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "enter_hotel_address"))
        tableView!.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getGooglePlaceCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StayAddressCell", for: indexPath) as! StayAddressCell
        cell.configCell(model: viewModel.getCellModel(at: indexPath))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getGooglePlace(indexPath: indexPath)
        viewModel.searchPlace(withId: model.id)
    }
}

extension StayAddressVC: StayAddressVMDelegate {
    
    func stayAddressVMSelectedPlace(id: String, location: TRPLocation, hotelAddress: String, name: String?) {
        guard let name = name else {return}
        
        let stayAddress = TRPAccommodation(name: name, referanceId: id, address: hotelAddress, coordinate: location)
        delegate?.stayAddressSelectedPlace(stayAddress: stayAddress)
        self.dismiss(animated: true)
//        backButtonPressed()
    }
    
    override func viewModel(dataLoaded: Bool) {
        guard let tb = tableView else {return}
        tb.reloadData()
    }
}
