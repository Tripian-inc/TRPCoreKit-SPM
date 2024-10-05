//
//  ProfileSubTitle.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-04-19.
//

import UIKit

@IBDesignable
class ProfileSubTitle: UIView {
    
    private let nibName = "ProfileSubTitle"
    @IBOutlet weak var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        guard let view = loadNib(nibName: nibName) else { return }
        view.frame = self.bounds
        self.addSubview(view)
        
        label.font = trpTheme.font.header1
        label.textColor = trpTheme.color.tripianBlack
    }
}
