//
//  ExperienceAvailabilityPeopleCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-03.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class ExperienceAvailabilityPeopleCell: UITableViewCell {
    
    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = "Children"
        return label
    }()
    
    public lazy var subTitleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 1
        label.text = "(Age 3-7)"
        return label
    }()
    
    private lazy var increaseButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("+", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(increaseBtnPressed), for: .touchDown)
        return btn
    }()
    
    private lazy var decreaseButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("-", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(decreaseBtnPressed), for: .touchDown)
        return btn
    }()
    
    private lazy var peopleCountLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 1
        label.textAlignment = .center
        label.text = "0"
        return label
    }()
    private var model: ExpericePeopleCellModel?
    var peopleCount = 0 {
        didSet {
            peopleCountLabel.text = "\(peopleCount)"
            if let model = model {
                action?(ExperinceSelectedPeople( name: model.title, count: peopleCount))
            }
        }
    }
    
    var action: ((_ people: ExperinceSelectedPeople) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [titleLabel, subTitleLabel, increaseButton, decreaseButton, peopleCountLabel].forEach { addSubview($0) }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            
            subTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            increaseButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            increaseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            increaseButton.widthAnchor.constraint(equalToConstant: 40),
            
            peopleCountLabel.trailingAnchor.constraint(equalTo: increaseButton.leadingAnchor, constant: 0),
            peopleCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            peopleCountLabel.widthAnchor.constraint(equalToConstant: 20),
            
            decreaseButton.trailingAnchor.constraint(equalTo: peopleCountLabel.leadingAnchor, constant: 0),
            decreaseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            decreaseButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    public func setModel(_ model: ExpericePeopleCellModel) {
        self.model = model
    }
    
    @objc func increaseBtnPressed() {
        peopleCount += 1
    }
    
    @objc func decreaseBtnPressed() {
        if peopleCount > 0 {
            peopleCount -= 1
        }
    }
}
