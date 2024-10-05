//
//  ExperienceDetailSubTitleTextCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 24.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit


class ExperienceDetailSubTitleTextCell: UITableViewCell {
    
    public lazy var textLbl: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = "TİTLE"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupViews() {
        addSubview(textLbl)
        textLbl.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        textLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        textLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        self.bottomAnchor.constraint(equalTo: textLbl.bottomAnchor, constant: 8).isActive = true
    }
    
    
    
    public func set(title: String, content: String) {
        let _title = "\(title):"
        let attributed = _title.addStyle([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 15, weight: .regular)])
        attributed.addString(" " + content, syle: [.foregroundColor: TRPColor.darkGrey, .font: UIFont.systemFont(ofSize: 15)])
        textLbl.attributedText = attributed
    }
}
