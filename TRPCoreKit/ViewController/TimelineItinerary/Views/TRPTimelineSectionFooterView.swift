//
//  TRPTimelineSectionFooterView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 03.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

protocol TRPTimelineSectionFooterViewDelegate: AnyObject {
    func sectionFooterViewDidTapAdd(_ view: TRPTimelineSectionFooterView, section: Int)
}

class TRPTimelineSectionFooterView: UITableViewHeaderFooterView {
    
    static let reuseIdentifier = "TRPTimelineSectionFooterView"
    
    weak var delegate: TRPTimelineSectionFooterViewDelegate?
    private var sectionIndex: Int = 0
    
    // MARK: - UI Components
    private let horizontalLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        return view
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral200.uiColor
        button.layer.cornerRadius = 16
        
        let image = TRPImageController().getImage(inFramework: "ic_plus", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        
        return button
    }()
    
    // MARK: - Initialization
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(horizontalLine)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            horizontalLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 48),
            addButton.heightAnchor.constraint(equalToConstant: 32),
            addButton.leadingAnchor.constraint(equalTo: horizontalLine.trailingAnchor, constant: 16)
        ])
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        delegate?.sectionFooterViewDidTapAdd(self, section: sectionIndex)
    }
    
    // MARK: - Configuration
    func configure(section: Int) {
        self.sectionIndex = section
    }
}

