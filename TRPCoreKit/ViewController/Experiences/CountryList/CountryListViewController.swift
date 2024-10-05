//
//  CountryListViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-26.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
public protocol CountryListViewControllerDelegate: AnyObject {
    func countryListViewControllerSelectedCountry(_ name: String, code: String)
}
struct Country {
    var name: String
    var code: String
}

class CountryListViewController: TRPBaseUIViewController {
    
    private var tb: EvrTableView = EvrTableView()
    private var countries = [Country]()
    public weak var delegate: CountryListViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupViews() {
        super.setupViews()
        getCountryList()
        setupTableView()
    }
    
    private func getCountryList() {
        var countries: [Country] = []

        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            let county = Country(name: name, code: code)
            countries.append(county)
        }
        self.countries = countries
    }
}

extension CountryListViewController: UITableViewDelegate, UITableViewDataSource{
    private func setupTableView() {
        tb = EvrTableView(frame: CGRect.zero)
        view.addSubview(tb)
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tb.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tb.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tb.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tb.delegate = self
        tb.dataSource = self
        tb.rowHeight = 48;
        tb.backgroundColor = testColor
        tb.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tb.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let model = countries[indexPath.row]
        cell.textLabel?.text = "\(model.name)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = countries[indexPath.row]
        dismiss(animated: true) {
            self.delegate?.countryListViewControllerSelectedCountry(model.name, code: model.code)
        }
    }
}
