//
//  CreateTripSelectRestaurantPreferVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

protocol CreateTripSelectRestaurantPreferVCDelegate: AnyObject {
    func createTripSelectRestaurantPreferVCSetSelectedAnswer(_ answer: SelectableAnswer, question: SelectableQuestionModelNew)
}

@objc(SPMCreateTripSelectRestaurantPreferVC)
class CreateTripSelectRestaurantPreferVC: TRPBaseUIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    public var viewModel: CreateTripSelectRestaurantPreferViewModel!
    public weak var delegate: CreateTripSelectRestaurantPreferVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()

    }
    
    override func setupViews() {
        super.setupViews()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.separatorStyle = .none
        
        titleLabel.font = trpTheme.font.display
        titleLabel.text = viewModel.getTitle()
    }

}

extension CreateTripSelectRestaurantPreferVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getRowCount()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripSelectItemCell", for: indexPath) as! CreateTripSelectItemCell
        let answer = viewModel.getAnswer(indexPath: indexPath)
        cell.label.text = answer.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAnswer = viewModel.getAnswer(indexPath: indexPath)
        self.setSelectedAnswer(selectedAnswer)
    }
}

extension CreateTripSelectRestaurantPreferVC {
    
    private func setSelectedAnswer(_ answer: SelectableAnswer) {
        self.delegate?.createTripSelectRestaurantPreferVCSetSelectedAnswer(answer, question: viewModel.selectableQuestion!)
        self.dismiss(animated: true)
    }
}
