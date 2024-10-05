//
//  TRPCirleButton.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 4.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public class TRPCirleButton: UIButton {
    
    public var textFontSize: CGFloat = 10 {
        didSet {
            titleLbl.font = UIFont.systemFont(ofSize: textFontSize)
        }
    }
    
    public var textColor: UIColor = UIColor.black {
        didSet{
            titleLbl.textColor = textColor
        }
    }
    
    public var normalBg: UIColor = UIColor.white {
        didSet {
            self.backgroundColor = normalBg
        }
    }
    
    private lazy var titleLbl: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = UIFont.systemFont(ofSize: textFontSize)
        lbl.textColor = textColor
        lbl.sizeToFit()
        lbl.adjustsFontSizeToFitWidth = true
        lbl.backgroundColor = .white
        lbl.layer.masksToBounds = true
        lbl.layer.cornerRadius = 3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    var normalImage: UIImage?
    var selectedImage: UIImage?
    var titleName: String?
    private var isAutoSelection: Bool = true
    
    
    public init(frame:CGRect,
         normalImage: UIImage,
         selectedImage: UIImage? = nil,
         titleName: String? = nil,
         isAutoSelection: Bool = true) {
        super.init(frame: frame)
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.titleName = titleName
        self.isAutoSelection = isAutoSelection
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        
        if titleName != nil {
            addSubview(titleLbl)
            if let titleName = titleName {
                titleLbl.text = titleName
            }
            titleLbl.widthAnchor.constraint(equalTo: self.widthAnchor, constant: UIScreen.main.bounds.width < 325.0 ? 15 : 17).isActive = true
            titleLbl.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -11).isActive = true
            titleLbl.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 6).isActive = true
            titleLbl.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        }
        backgroundColor = normalBg
        setImage(normalImage, for: .normal)
        if let selected = selectedImage {
            setImage(selected, for: .selected)
        }
        
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        addTarget(self, action: #selector(onPressed), for: UIControl.Event.touchUpInside)
    }
    
    @objc func onPressed() {
        if isAutoSelection {
            isSelected = !isSelected
        }
    }
    
}
