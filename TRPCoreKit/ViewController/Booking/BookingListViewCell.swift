//
//  BookingListViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class BookingListViewCell: UITableViewCell {
    
    public var index:Int?
    
    private lazy var placeImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = TRPColor.darkGrey
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.layer.cornerRadius = 60 / 2
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        return imageView
    }()
    
    private(set) lazy var mainVerticalStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        return stack
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.black
        label.text = ""
        label.numberOfLines = 1
        return label
    }()
    
    lazy var subLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TRPColor.darkGrey
        label.text = ""
        label.numberOfLines = 1
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setup() {
        self.selectionStyle = .none
        addSubview(placeImage)
        addSubview(titleLabel)
        addSubview(subLabel)
        addSubview(mainVerticalStackView)
        placeImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        placeImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        mainVerticalStackView.leadingAnchor.constraint(equalTo: placeImage.trailingAnchor, constant: 16).isActive = true
        mainVerticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        //mainVerticalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        //mainVerticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        mainVerticalStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        
        mainVerticalStackView.addArrangedSubview(titleLabel)
        mainVerticalStackView.addArrangedSubview(subLabel)
    }
    
    func addSubtitle(provider: String, dateTime: String) {
        let attributed = provider.addStyle([.foregroundColor: TRPColor.pink])
        attributed.addString(" " + dateTime, syle: [.foregroundColor: TRPColor.darkGrey])
        subLabel.attributedText = attributed
    }
    
    
    public func getImageView() -> UIImageView {
        return placeImage
    }
}
