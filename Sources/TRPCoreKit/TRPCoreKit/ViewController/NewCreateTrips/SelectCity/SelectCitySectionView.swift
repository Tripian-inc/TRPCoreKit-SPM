//
//  SelectCitySectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 7.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit
public enum Continent: String {
    case northAmerica = "North America"
    case southAmerica = "South America"
    case africa = "Africa"
    case asia = "Asia"
    case australia = "Australia"
    case europe = "Europe"
    
    func getImage() -> UIImage? {
        var imageName: String = ""
        switch self {
        case .northAmerica:
            imageName = "north_america"
        case .southAmerica:
            imageName = "south_america"
        case .africa:
            imageName = "africa"
        case .asia:
            imageName = "asia"
        case .australia:
            imageName = "australia"
        case .europe:
            imageName = "europe"
        }
        return TRPImageController().getImage(inFramework: imageName, inApp: nil)
    }
}

class SelectCitySectionView: UIView {
    private let nibName = "SelectCitySectionView"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func commonInit() {
        self.frame.size.height = 70
        guard let view = loadNib(nibName: nibName) else {return}
        view.frame = self.bounds
        self.addSubview(view)
        
        self.backgroundColor = UIColor.white
        
        label.font = trpTheme.font.header2
        label.textColor = trpTheme.color.tripianBlack
    }
    
    func configureData(continentName: String) {
        label.text = continentName
        let continent = Continent(rawValue: continentName)
        imageView.image = continent?.getImage()
    }

}
