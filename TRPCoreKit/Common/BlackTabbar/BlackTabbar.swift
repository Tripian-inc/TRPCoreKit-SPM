//
//  BlackTabbar.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-21.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

@objc(SPMBlackTabbar)
class BlackTabbar: UIView {

    var action: ((_ type: BlackTabbarItemType) -> Void)?
    private var shapeLayer: CALayer?
    var height: CGFloat = 74
    var fillColor: UIColor = .white
    var strokeColor: UIColor = UIColor.clear
    var strokeLineWidth: CGFloat = 0.0
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var btnFavorites: TabbarButton!
    @IBOutlet weak var btnPlanner: TabbarButton!
    @IBOutlet weak var btnExperiences: TabbarButton!
    @IBOutlet weak var btnPlaces: TabbarButton!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
//        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "BlackTabbar", bundle: Bundle.module)
        guard let _view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {return}
        _view.frame = self.bounds
        addSubview(_view)
        
        containerView.backgroundColor = .white
        
        btnFavorites.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.favorites.title"), for: .normal)
        btnPlanner.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "planner"), for: .normal)
        btnExperiences.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.experiences"), for: .normal)
        btnPlaces.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.places"), for: .normal)
    }
    
    @IBAction func mapPressed(_ sender: Any) {
        action?(.experiences)
    }
    @IBAction func localExperiencesPressed(_ sender: Any) {
        action?(.experiences)
    }
    
    @IBAction func itineraryPressed(_ sender: Any) {
        action?(.itinerary)
    }
    
    //MARK: - SDK çıkılması için favori olarak güncellendi
    @IBAction func offersPressed(_ sender: Any) {
//        action?(.offer)
        action?(.favourite)
    }
    
    @IBAction func searchPressed(_ sender: Any) {
        action?(.search)
    }
    @IBAction func favoriteAction(_ sender: Any) {
        action?(.favourite)
    }
    
}

@objc(SPMTabbarButton)
class TabbarButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    fileprivate func setupUI() {
//        backgroundColor = trpTheme.color.blue
//        layer.cornerRadius = 26
        setTitleColor(UIColor.black, for: .normal)
        titleLabel?.font = trpTheme.font.caption
        contentEdgeInsets = .zero// UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        if #available(iOS 15.0, *) {
            var configuration = configuration
            configuration?.contentInsets = .zero
            self.configuration = configuration
        }
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = self.imageView {
            imageView.frame.origin.x = (self.bounds.size.width - imageView.frame.size.width) / 2.0
            imageView.frame.origin.y = 12.0
        }
        if let titleLabel = self.titleLabel {
            titleLabel.frame.origin.x = (self.bounds.size.width - titleLabel.frame.size.width) / 2.0
            titleLabel.frame.origin.y = self.bounds.size.height - titleLabel.frame.size.height - 5
        }
    }
}
