//
//  SelectCityVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit




public protocol SelectCityVCDelegate: AnyObject {
    func selectedCity(cityId: Int, city: TRPCity)
}

@objc(SPMSelectCityVC)
public class SelectCityVC: TRPBaseUIViewController {
    //MARK: - Properties
    var viewModel: SelectCityViewModel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    public weak var delegate: SelectCityVCDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.getMainTitle();
        //Pushdan dolayı geç yükleniyor o yüzden start buraya eklendi.
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        self.definesPresentationContext = true
        setupTableView()
        setupSearchBar()
        addBackButton(position: .left)
        hiddenBackButtonTitle()
        
        setupStepView()
    }
    
    private func setupStepView() {
        let view = CreateTripStepView()
        view.setStep(step: viewModel.getCurrentStep())
        addNavigationBarCustomView(view: view)
    }
}

//MARK: TableView
extension SelectCityVC: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
        tableView.backgroundColor = UIColor.white
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 50
        tableView.register(cellClass: UITableViewCell.self)
        tableView.separatorStyle = .singleLine
    }
    
    //Section count
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionCount()
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let vw = SelectCitySectionView()
//        lbl.translatesAutoresizingMaskIntoConstraints = false
        let continentName = viewModel.getSectionTitle(index: section)
        vw.configureData(continentName: continentName)
        return vw
    }

    //Section Title
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.getSectionTitle(index: section)
    }
    
    //Cell Count
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCityCount(inSection: section)
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TRPAppearanceSettings.SelectCity.headerHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
        
        let cityName = viewModel.getCityName(indexPath: indexPath)
        cell.textLabel?.text = cityName
        cell.textLabel?.font = trpTheme.font.body2
        cell.textLabel?.textColor = trpTheme.color.tripianTextPrimary
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cityModel: SelectCityCellModel = viewModel.getCity(indexPath: indexPath)
        selectCity(model: cityModel)
    }

}

//MARK: City selection
extension SelectCityVC {
    func selectCity(model: SelectCityCellModel) {
        self.delegate?.selectedCity(cityId: model.cityId, city: model.city)
        self.dismiss(animated: true)
    }
}

//MARK: Search Bar
extension SelectCityVC: UISearchBarDelegate{
    
    func setupSearchBar() {
        //To remove borders
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = trpTheme.color.extraBG
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = trpTheme.color.extraSub
        }
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.filterContentForSearchText(searchBar.text!)
    }
}

extension SelectCityVC: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    public func updateSearchResults(for searchController: UISearchController) {
        viewModel.filterContentForSearchText(searchController.searchBar.text!)
    }

}

extension SelectCityVC {
    
    public override func viewModel(dataLoaded: Bool) {
//        if viewModel.isOnlyOneCity() {
//            self.selectCity(model: viewModel.getFirstCity())
//            return
//        }
        tableView.reloadData()
    }
    
}
