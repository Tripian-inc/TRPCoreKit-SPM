//
//  AddPlaceListTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit


let testColor = UIColor.white //UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)



class AddPlaceListTableViewCell: UITableViewCell {
    
    private let enRoute = "en route"
    
    public var isCloseToday: Bool = false
    public var isOnRota: Bool = false
    public var index:Int?
    public var isSuggestedByTripian: Bool = true {
        didSet {
            tripianCheckImage.isHidden = !isSuggestedByTripian
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = "Title"
        return label
    }()
    
    public lazy var distanceLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        
        return label
    }()

    private lazy var explainLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "en route"
        lbl.textColor = UIColor.black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        return lbl
    }()
    
    private lazy var tripianCheckImage: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return imgView
    }()
    
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
    
    private lazy var closeTodayLabel: UILabel = {
        let label = UILabel();
        label.font = UIFont.systemFont(ofSize: 9)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 30).isActive = true
        label.heightAnchor.constraint(equalToConstant: 26).isActive = true
        label.textColor = TRPColor.pink
        label.numberOfLines = 0
        label.text = "Close Today"
        return label
    }()
    
    private var titleCenterY: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func setTitle(_ text: String) {
        self.titleLabel.text = text
    }
    
    public func getImageView() -> UIImageView {
        return placeImage
    }
    
    private func setup() {
        self.selectionStyle = .none
        backgroundColor = testColor
        setupImage()
        setupTitle()
        setupTripianCheckIcon()
        setupDistanceLabel()
        setupExplainLabel()
    }
    
    
    func setExplaintText(text: NSAttributedString?) {
        explainLabel.isHidden = true
        if let text = text  {
            explainLabel.isHidden = false
            explainLabel.attributedText = text
            titleCenterY?.constant = -6
        }
    }
    
}

// MARK: - Set UI
extension AddPlaceListTableViewCell {
    
    fileprivate func setupImage() {
        addSubview(placeImage)
        placeImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        placeImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        placeImage.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        placeImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
    }
    
    fileprivate func setupTitle() {
        addSubview(titleLabel)
        titleCenterY = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        titleCenterY!.isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: placeImage.trailingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo:  trailingAnchor, constant: -32).isActive = true
    }
    
    fileprivate func setupTripianCheckIcon() {
        addSubview(tripianCheckImage)
        tripianCheckImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        tripianCheckImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        if let image = TRPImageController().getImage(inFramework: "tripian_check_icon", inApp: TRPAppearanceSettings.AddPoi.alternativePoiIcon) {
            tripianCheckImage.image = image
        }
    }
    
    fileprivate func setupDistanceLabel() {
        addSubview(distanceLabel)
        distanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        distanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
    }
    
    fileprivate func setupExplainLabel() {
        addSubview(explainLabel)
        explainLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 0).isActive = true
        explainLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2).isActive = true
    }
}
