//
//  TRPCallOutController.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 1.10.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public enum AddRemoveNavButtonStatus{
    case none, add, remove, navigation, alternative, inRoute
    
    public func imageName() -> String? {
        switch self {
        case .none:
            return nil
        case .add:
            return "add_btn"
        case .remove:
            return "remove_btn"
        case .navigation:
            return "navigation_addplace_btn_x"
        case .alternative:
            return "alternative_poi_icon"
        case .inRoute:
            return "route_btn"
        }
    }
}
public struct CallOutCellMode {
    
    var id:String
    var name: String
    var poiCategory:String
    var startCount: Float
    var reviewCount: Int
    var price: Int
    var rightButtonStatus: AddRemoveNavButtonStatus?
    
    public init(id: String,
                name: String,
                poiCategory: String,
                startCount: Float,
                reviewCount: Int,
                price: Int,
                rightButton: AddRemoveNavButtonStatus? = nil) {
        self.id = id
        self.name = name
        self.poiCategory = poiCategory
        self.startCount = startCount
        self.reviewCount = reviewCount
        self.price = price
        self.rightButtonStatus = rightButton
    }
    
}

public class TRPCallOutController {
    
    public enum CallOutStatus {
        case willShow, didShow, willHidden, didHidden
    }
    
    let transformY: CGFloat = 250
    var parentView: UIView
    var cell: TRPCallOutCell?;
    public var isOpen = false
    public var isAnimating = false
    public var cellPressed: ((_ id: String,  _ inRoute: Bool)-> Void)? = nil
    public var action: ((_ status:AddRemoveNavButtonStatus, _ id: String) -> Void)? = nil
    public var callOutStatus: ((_ status:CallOutStatus) -> Void)? = nil
    private var model: CallOutCellMode?
    private var addBtnImage: UIImage?
    private var removeBtnImage: UIImage?
    private var navigationBtnImage: UIImage?
    public var bottomSpace: CGFloat {
        didSet {
            if cell != nil {
                cell!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -1 * bottomSpace).isActive = true
            }
        }
    }
    
    public init(inView: UIView,
                addBtnImage: UIImage?,
                removeBtnImage: UIImage?,
                navigationBtnImage: UIImage?,
                bottomSpace: CGFloat = 62) {
        parentView = inView
        self.addBtnImage = addBtnImage
        self.removeBtnImage = removeBtnImage
        self.navigationBtnImage = navigationBtnImage
        self.bottomSpace = bottomSpace
        commonInit()
    }
    
    private func commonInit() {
        cell = TRPCallOutCell()
        cell!.getImageView().image = nil
        parentView.addSubview(cell!)
        cell!.translatesAutoresizingMaskIntoConstraints = false
        cell!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 32).isActive = true
        cell!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -32).isActive = true
        // DOTO
        cell!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -1 * bottomSpace).isActive = true
        cell!.transform = CGAffineTransform(translationX: 0, y: self.transformY)
        cell!.cellPressed = { [weak self] id in
            guard let strongSelf = self else {return}
            var inRoute = false
            if let m = strongSelf.model?.rightButtonStatus {
                if m == .remove {
                    inRoute = true
                }
            }
            strongSelf.cellPressed?(id,inRoute)
        }
        cell!.rightButtonAction = { [weak self] status, id in
            guard let strongSelf = self else {return}
            strongSelf.action?(status,id)
        }
    }
    
    public func show(model: CallOutCellMode){
        self.model = model
        showAnimation()
        
        var btnImage: UIImage?
        if let status = model.rightButtonStatus {
            switch  status{
            case .add:
                btnImage = addBtnImage
            case .remove:
                btnImage = removeBtnImage
            case .navigation:
                btnImage = navigationBtnImage
            default:
                ()
            }
        }
        cell?.addRemoveNavigationButton.setImage(btnImage, for: .normal)
        cell?.updateModel(model)
    }
    
    public func getCellImageView() -> UIImageView? {
        return cell?.getImageView()
    }
    
    public func hidden() {
        if cell == nil {return}
        cell?.getImageView().image = nil
        hiddenAnimation()
    }
    
    private func showAnimation() {
        callOutStatus?(.willShow)
        cell?.transform = CGAffineTransform(translationX: 0, y: transformY)
        UIView.animate(withDuration: 0.2, delay:0, options: .curveEaseOut, animations: {
            self.cell?.transform = CGAffineTransform.identity
            self.cell?.alpha = 1
        }) { (_) in
            self.cell?.transform = CGAffineTransform.identity
            self.cell?.alpha = 1
            self.callOutStatus?(.didShow)
        }
    }
    
    private func hiddenAnimation() {
        callOutStatus?(.willHidden)
        UIView.animate(withDuration: 0.2, delay:0, options: .curveEaseIn, animations: {
            self.cell?.transform = CGAffineTransform(translationX: 0, y: self.transformY)
            self.cell?.alpha = 0
        }) { (_) in
            self.cell?.alpha = 0
            self.cell?.transform = CGAffineTransform(translationX: 0, y: self.transformY)
            self.callOutStatus?(.didHidden)
        }
    }
    
}

class TRPCallOutCell: UIView {
    
    private let imageView: UIImageView = {
        let img = UIImageView()
        img.backgroundColor = TRPColor.darkGrey
        img.layer.cornerRadius = 64 / 2
        img.clipsToBounds = true
        img.contentMode = UIView.ContentMode.scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = TRPColor.darkGrey
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = TRPColor.darkGrey
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = TRPColor.darkGrey
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Restaurant"
        label.numberOfLines = 1
        return label
    }()
    
    public lazy var addRemoveNavigationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 26).isActive = true
        button.heightAnchor.constraint(equalToConstant: 26).isActive = true
        button.addTarget(self, action: #selector(addRemoveNavigationButtonPressed), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    
    public var rightButtonStatus = AddRemoveNavButtonStatus.add
    private let padding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    private var model: CallOutCellMode?
    public var cellPressed: ((_ id: String) -> Void)? = nil
    public var rightButtonAction: ((_ status:AddRemoveNavButtonStatus, _ id: String) -> Void)? = nil
    private var addBtnImage: UIImage?
    private var removeBtnImage: UIImage?
    private var navigationBtnImage: UIImage?
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let stackView   = UIStackView()
    let star = TRPStar(frame: CGRect(x: 0, y: 0, width: 100, height: 12))
    
    public func updateModel(_ model : CallOutCellMode){
        self.model = model
        titleLabel.text = model.name
        typeLabel.attributedText = explaineStringCreater(type: model.poiCategory, price: model.price)
        
        if Int(model.startCount) < 1 {
            star.isHidden = true
            stackView.removeArrangedSubview(star)
        }else {
            star.isHidden = false
            stackView.addArrangedSubview(star)
            star.setRating(Int(model.startCount))
        }
        
        if let right = model.rightButtonStatus {
            rightButtonStatus = right
            addRemoveNavigationButton.isHidden = false
            addRemoveNavigationButton.isUserInteractionEnabled = true
            //addRemoveNavigationButton.setImage(UIImage(named:image), for: .normal)
        }else {
            addRemoveNavigationButton.isHidden = true
            addRemoveNavigationButton.isUserInteractionEnabled = false
        }
    }
    
    private func explaineStringCreater(type: String, price: Int) -> NSMutableAttributedString {
        var text = "\(type)"
        if price > 0 {
            text += " - \(self.priceString(price: price))"
//            text += " - \(String(repeating: "$" , count: 4))"
        }
        let normalAttributes  = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),.foregroundColor: UIColor.lightGray]
        let sentence = NSMutableAttributedString(string: text, attributes: normalAttributes)
//        if price > 0 {
//            let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),.foregroundColor: UIColor.darkGray]
//            let smallAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8),.foregroundColor: UIColor.lightGray]
//            sentence.setAttributes(largeAttributes, range: NSRange(location: type.lengthOfBytes(using: String.Encoding.utf8) + 3, length: price))
//            sentence.setAttributes(smallAttributes, range: NSRange(location: type.lengthOfBytes(using: String.Encoding.utf8) + 3 + price, length: 4 - price))
//        }
        return sentence
    }
    
    private func priceString(price: Int) -> NSMutableAttributedString {
        let boldPrice = String(repeating: "$" , count: 4)
        let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),.foregroundColor: UIColor.darkGray]
        let smallAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 8),.foregroundColor: UIColor.lightGray]
        let attributedSentence = NSMutableAttributedString(string: boldPrice, attributes: smallAttributes)
        attributedSentence.setAttributes(largeAttributes, range: NSRange(location: 0, length: price))
        return attributedSentence
    }
    
    private func commonInit() {
        layoutIfNeeded()
        backgroundColor = UIColor.white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        heightAnchor.constraint(equalToConstant: 64 + padding.top + padding.bottom).isActive = true
        addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left).isActive = true
        
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.leading
        stackView.spacing   = 6.0
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.top).isActive = true
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(typeLabel)
        stackView.addArrangedSubview(star)
        star.show()
        
        addSubview(addRemoveNavigationButton)
        addRemoveNavigationButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        addRemoveNavigationButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(pressed))
        addGestureRecognizer(tap)
        
    }
    
    public func getImageView() -> UIImageView {
        return imageView
    }
    
    @objc func pressed() -> Void {
        if let id = model?.id {
            cellPressed?(id)
        }
    }
    
    
    @objc func addRemoveNavigationButtonPressed() {
        if let id = model?.id {
            rightButtonAction?(rightButtonStatus, id)
        }
    }
    
}
