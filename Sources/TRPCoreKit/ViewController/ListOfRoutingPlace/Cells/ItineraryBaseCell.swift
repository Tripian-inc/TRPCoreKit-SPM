//
//  ItineraryBaseCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

class ItineraryBaseCell: UITableViewCell {
    
    typealias ButtonClicked = () -> Void
    public var uberHandler: ButtonClicked?
    var bottomContainerHeight: NSLayoutConstraint?
    let rightSpaceForEditing: CGFloat = 50
    
    //MARK: - PLACEIMAGE AND ORDER
    lazy var poiImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.darkGray
        imageView.layer.cornerRadius = 32
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        return imageView
    }()
    
    lazy var orderContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black
        view.widthAnchor.constraint(equalToConstant: 24).isActive = true
        view.heightAnchor.constraint(equalToConstant: 24).isActive = true
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var orderlabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.text = ""
        return label
    }()
    
    
    //MARK: - BOTTOM BAR
    
    lazy var bottomDistanceView: UIView = {
        let grayView = UIView()
        grayView.translatesAutoresizingMaskIntoConstraints = false
        grayView.backgroundColor = TRPColor.ultraLightGrey.withAlphaComponent(0.7)
        return grayView
    }()
    
    lazy var distanceInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.text = ""
        return label
    }()
    
    lazy var distanceImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    public lazy var uberButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        btn.setTitle("Book a Ride", for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(uberButtonPressed), for: .touchUpInside)
        
        if let uberLogo = TRPImageController().getImage(inFramework: "uber_icon_white", inApp: nil) {
            btn.setImage(uberLogo, for: .normal)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        }
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        btn.layer.cornerRadius = 5
        return btn
    }()
    
    
    //MARK: - CENTER VIEWS
    
    lazy var mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.vertical
        stack.alignment = .leading
        stack.spacing = 6
        //stack.distribution = .equalSpacing
        return stack
    }()
    
    lazy var poiNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 1
        label.textColor = TRPAppearanceSettings.ListOfRouting.poiDetailTextColor
        label.text = ""
        return label
    }()
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        contentView.isHidden = true
        setupBottomViews()
        setupImageAndOrder()
        setupCenterViews()
        setupUberButtons()
        //combineBottom()
        
    }
    
    
    /// Yürüme veya araç uzaklığına göre butonları ve gösterilecek labellerı ayarlar
    /// - Parameter type: Yurume tipi
    func setDistanceImage(type: ItineraryDistanceType) {
        
        if type == .car {
            if let img = TRPImageController().getImage(inFramework: "drive", inApp: TRPAppearanceSettings.ItineraryUserDistance.taxi)!.maskWithColor(color: TRPColor.taxiYellow) {
                distanceImageView.image = img
                
            }
            showUberButton(true)
            if bottomContainerHeight != nil {
                bottomContainerHeight!.constant = TRPAppearanceSettings.Providers.uber ? 36 : 24
            }
            distanceInfoLabel.isHidden = false
        }else if type == .walking {
            if let img = TRPImageController().getImage(inFramework: "man-walking-directions-button", inApp: TRPAppearanceSettings.ItineraryUserDistance.walkingMan) {
                distanceImageView.image = img
            }
            showUberButton(false)
            if bottomContainerHeight != nil {
                bottomContainerHeight!.constant = 24
            }
            distanceInfoLabel.isHidden = false
        }else if type == .none{ // eğer mesela yoksa. Bu TableView in son elemanında kullanılır.
            distanceImageView.image = nil
            showUberButton(false)
            if bottomContainerHeight != nil {
                bottomContainerHeight!.constant = 0
            }
            distanceInfoLabel.isHidden = true
        }
    }
    
    private func showUberButton(_ state: Bool) {
        guard TRPAppearanceSettings.Providers.uber else {return}
        uberButton.isHidden = !state
        uberButton.isUserInteractionEnabled = state
    }
    
    @objc func uberButtonPressed() {
        uberHandler?()
    }
    
    
    public func addViewInCenterStack(_ stack: UIStackView) {
        
    }
}

//MARK: - SETUP VIEWS
extension ItineraryBaseCell {
    
    private func setupBottomViews() {
        addSubview(bottomDistanceView)
        bottomContainerHeight = bottomDistanceView.heightAnchor.constraint(equalToConstant: 24)
        bottomContainerHeight!.isActive = true
        bottomDistanceView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomDistanceView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomDistanceView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
       // bottomAnchor.constraint(equalTo: bottomDistanceView.bottomAnchor).isActive = true
        bottomDistanceView.addSubview(distanceImageView)
        distanceImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        distanceImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        distanceImageView.leadingAnchor.constraint(equalTo: bottomDistanceView.leadingAnchor, constant: 16).isActive = true
        distanceImageView.centerYAnchor.constraint(equalTo: bottomDistanceView.centerYAnchor).isActive = true
        
        bottomDistanceView.addSubview(distanceInfoLabel)
        distanceInfoLabel.centerYAnchor.constraint(equalTo: bottomDistanceView.centerYAnchor).isActive = true
        distanceInfoLabel.leadingAnchor.constraint(equalTo: distanceImageView.trailingAnchor, constant: 8).isActive = true
    }
    
    private func setupImageAndOrder() {
        //ImageView
        addSubview(poiImage)
        poiImage.widthAnchor.constraint(equalToConstant: 64).isActive = true
        poiImage.heightAnchor.constraint(equalToConstant: 64).isActive = true
        poiImage.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        poiImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        //Order Container
        addSubview(orderContainer)
        orderContainer.leadingAnchor.constraint(equalTo: poiImage.leadingAnchor, constant: -4).isActive = true
        orderContainer.topAnchor.constraint(equalTo: poiImage.topAnchor, constant: -4).isActive = true
        
        orderContainer.addSubview(orderlabel)
        orderlabel.leadingAnchor.constraint(equalTo: orderContainer.leadingAnchor, constant: 0).isActive = true
        orderlabel.trailingAnchor.constraint(equalTo: orderContainer.trailingAnchor, constant: 0).isActive = true
        orderlabel.topAnchor.constraint(equalTo: orderContainer.topAnchor, constant: 0).isActive = true
        orderlabel.bottomAnchor.constraint(equalTo: orderContainer.bottomAnchor, constant: 0).isActive = true
    }
    
    private func setupCenterViews() {
        addSubview(mainStackView)
        mainStackView.leadingAnchor.constraint(equalTo: poiImage.trailingAnchor, constant: 16).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -rightSpaceForEditing).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
       // mainStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        //bottomDistanceView.topAnchor.constraint(equalTo: mainStackView.bottomAnchor, constant: 16).isActive = true
        addViewInCenterStack(mainStackView)
    }
    
    private func setupUberButtons() {
        //bottomDistanceView.topAnchor.constraint(equalTo: poiImage.bottomAnchor, constant: 16).isActive = true
        if TRPAppearanceSettings.Providers.uber {
            bottomDistanceView.addSubview(uberButton)
            uberButton.centerYAnchor.constraint(equalTo: bottomDistanceView.centerYAnchor, constant: 0).isActive = true
            uberButton.leadingAnchor.constraint(equalTo: distanceInfoLabel.trailingAnchor, constant: 22).isActive = true
            uberButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
            uberButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
        }
    }
    
    
    public func combineBottom() {
        //bottomDistanceView.topAnchor.constraint(equalTo: mainStackView.bottomAnchor, constant: 16).isActive = true
        
    }
}
