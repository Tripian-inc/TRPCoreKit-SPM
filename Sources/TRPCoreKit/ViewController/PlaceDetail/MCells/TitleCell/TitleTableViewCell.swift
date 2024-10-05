//
//  TitleTableViewCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit

final class TitleTableViewCell: UITableViewCell {
    
    private let starViewWidth: CGFloat = 100
    var isRatingAvailable:Bool?
    var isExplainTextAvailable: Bool?
  
    private var bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()

    lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.textColor = TRPColor.pink
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.adjustsFontSizeToFitWidth = true
        return lbl
    }()
    
    lazy var globalRatingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.textColor = UIColor.black
        label.textAlignment = .left
        label.text = TRPLanguagesController.shared.getLanguageValue(for: "global_rating")
        return label
    }()
    
    lazy var inRouteExplain: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    
    private lazy var titleStackView: UIStackView = {
        let stackView   = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing   = 8.0
        return stackView
    }()
    
    
    var titleBottom: NSLayoutConstraint?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        backgroundColor = UIColor.clear
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func showSubTitle(starCount: Int, reviewCount: Int, explainText: NSAttributedString?) {
        if starCount > 0 && reviewCount > 0 {
            showRating(starCount, reviewCount)
        }
        
        if let explaine = explainText, explaine.length > 0 {
            showExplaineInRoute(explaine, starCount > 0 && reviewCount > 0)
        }
    }
}

//MARK: - UI Design
extension TitleTableViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isRatingAvailable = nil
        isExplainTextAvailable = nil
    }
    
    fileprivate func setup() {
        self.selectionStyle = .none
        contentView.isHidden = true
        setTitleView()
    }
    
    fileprivate func setTitleView() {
        addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        titleBottom = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        titleBottom?.isActive = true
    }
}

//MARK: - Show Rating
extension TitleTableViewCell {
    
    private func showRating(_ starCount: Int, _ reviewCount: Int) {
        isRatingAvailable = true
        let star = TRPStar(frame: CGRect(x: 0, y: 0, width: 100, height: 12))
        star.backgroundColor = UIColor.red
        addSubview(star)
        star.show()
        star.setRating(starCount)
        star.translatesAutoresizingMaskIntoConstraints = false
        addSubview(globalRatingLabel)
        globalRatingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        let horizontalPosition = calculateGlobalRatingHorizontalPosition()
        globalRatingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: horizontalPosition).isActive = true
        globalRatingLabel.text = "\(TRPLanguagesController.shared.getLanguageValue(for: "global_rating")): (\(reviewCount))"
        
        star.topAnchor.constraint(equalTo: globalRatingLabel.topAnchor, constant: 0).isActive = true
        star.leadingAnchor.constraint(equalTo: globalRatingLabel.trailingAnchor, constant: 8).isActive = true
        
        titleBottom?.constant -= 20
    }
    
    
    private func calculateGlobalRatingHorizontalPosition() -> CGFloat {
        return (frame.width - globalRatingLabel.frame.width) / 2 - starViewWidth/2
    }
}

//MARK: - Show Explain Text
extension TitleTableViewCell{
    private func showExplaineInRoute(_ text:NSAttributedString, _ isRatingAvaliable: Bool) {
        isExplainTextAvailable = true
        addSubview(inRouteExplain)
        
        inRouteExplain.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        inRouteExplain.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        if isRatingAvaliable {
            inRouteExplain.topAnchor.constraint(equalTo: globalRatingLabel.bottomAnchor, constant: 8).isActive = true
        }else {
            inRouteExplain.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        }
        inRouteExplain.attributedText = text
        titleBottom?.constant -= 20
    }
}
