//
//  TRPStar.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-06-03.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

@objc(SPMTRPStar2)
class TRPStar2: UIView {
    
    private let nibName = "TRPStar2"
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var star1: UIImageView!
    @IBOutlet weak var star2: UIImageView!
    @IBOutlet weak var star3: UIImageView!
    @IBOutlet weak var star4: UIImageView!
    @IBOutlet weak var star5: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        guard let view = loadNib(nibName: nibName) else {return}
        view.frame = self.bounds
        self.addSubview(view)
    }

    public func starRate(_ rate: Int) {
        let emptyStar = TRPImageController().getImage(inFramework: "star_empty", inApp: nil) ?? UIImage()
        let fillStar = TRPImageController().getImage(inFramework: "star_fill", inApp: nil) ?? UIImage()
        switch rate {
        case 1:
            star1.image = fillStar
            
            star2.image = emptyStar
            star3.image = emptyStar
            star4.image = emptyStar
            star5.image = emptyStar
        case 2:
            star1.image = fillStar
            star2.image = fillStar
            
            star3.image = emptyStar
            star4.image = emptyStar
            star5.image = emptyStar
        case 3:
            star1.image = fillStar
            star2.image = fillStar
            star3.image = fillStar
            
            star4.image = emptyStar
            star5.image = emptyStar
        case 4:
            star1.image = fillStar
            star2.image = fillStar
            star3.image = fillStar
            star4.image = fillStar
            
            star5.image = emptyStar
        case 5:
            star1.image = fillStar
            star2.image = fillStar
            star3.image = fillStar
            star4.image = fillStar
            star5.image = fillStar
        default:
            ()
        }
    }
    
}
