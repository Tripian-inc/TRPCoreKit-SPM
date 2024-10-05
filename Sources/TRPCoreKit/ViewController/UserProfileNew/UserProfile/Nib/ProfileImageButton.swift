//
//  ProfileImageButton.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-04-18.
//

import UIKit
@IBDesignable
class ProfileImageButton: UIView {
    
    private let nibName = "ProfileImageButton"
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var button: UIButton!
    
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
        
        label.font = trpTheme.font.body2
        label.textColor = trpTheme.color.tripianTextPrimary
        
        button.setTitle("", for: .normal)
    }
    
    
    
}
