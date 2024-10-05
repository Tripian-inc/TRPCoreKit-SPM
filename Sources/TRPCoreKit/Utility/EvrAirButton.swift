//
//  EvrAirButton.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 30.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit

protocol EvrAirButtonDelegate:AnyObject {
    func evrAirButtonPressed()
}

class EvrAirButton: UIView {
    
    public enum Direction {
        case right, left
    }
    
    private var isOpen = true
    private var isAnimated = false
    private var directions = EvrAirButton.Direction.right
    private let mainFrame: CGRect
    private let mainCenter: CGPoint
    private let mainR:CGFloat
    private let openWidth: CGFloat
    public weak var delegate: EvrAirButtonDelegate?
    
    
    lazy var topView: UIView = {
        var view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: 40,
                                        height: 40))
        view.backgroundColor = TRPColor.pink
        view.layer.cornerRadius = self.frame.width / 2
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: -1, height: 1)
        view.layer.shadowRadius = 1
       
        return view
    }()
    
    lazy var subView: UIView = {
        var view = UIView(frame: CGRect(x: 0,
                                        y: 0, width: 40, height: 40))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = self.frame.width / 2
        view.alpha = 1
        return view
    }()
    
    lazy var mainLbl: UILabel = {
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        lbl.text = "Show Alternatives"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)
        lbl.textAlignment = .right
        lbl.alpha = 0
        lbl.textColor = UIColor.black
        return lbl
    }()
    
    lazy var img: UIImageView = {
        let mi =  TRPImageController().getImage(inFramework: "alternativeonmap", inApp: TRPAppearanceSettings.Common.userButtonImage)
       var img = UIImageView(image: mi)
        img.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return img
    }()
    
    
    init(center:CGPoint,
         r:CGFloat,
         openWidth: CGFloat,
         isOpen:Bool,
         direction: EvrAirButton.Direction) {
        self.directions = direction
        mainCenter = center
        self.mainR = r
        let frame = CGRect(x: center.x ,
                           y: center.y,
                           width: r * 2,
                           height: r * 2)
        self.mainFrame = frame
        self.openWidth = openWidth
        super.init(frame: frame)
        
        backgroundColor = UIColor.lightGray
        let tap = UITapGestureRecognizer(target: self, action: #selector(pressed))
        addGestureRecognizer(tap)
        subView.isUserInteractionEnabled = true
        subView.addGestureRecognizer(tap)
        topView.isUserInteractionEnabled = true
        topView.addGestureRecognizer(tap)
        layer.cornerRadius = frame.height / 2
        self.isUserInteractionEnabled = true
        addSubview(subView)
        subView.frame = CGRect(x: 0, y: 0, width: mainR * 2, height: mainR * 2)
        addText()
        addSubview(topView)
        
        topView.frame = CGRect(x: 0, y: 0, width: mainR * 2, height: mainR * 2)
        topView.addSubview(img)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 24).isActive = true
        img.heightAnchor.constraint(equalToConstant: 24).isActive = true
        img.centerXAnchor.constraint(equalTo: topView.centerXAnchor, constant: 0).isActive = true
        img.centerYAnchor.constraint(equalTo: topView.centerYAnchor, constant: -1).isActive = true
    }
    
    
    func addText() {
        addSubview(mainLbl)
        mainLbl.translatesAutoresizingMaskIntoConstraints = false
        mainLbl.widthAnchor.constraint(equalToConstant: openWidth).isActive = true
        mainLbl.heightAnchor.constraint(equalToConstant: mainR * 2).isActive = true
        if directions == .left {
            mainLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24).isActive = true
            mainLbl.textAlignment = .right
        }else {
            mainLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: mainR).isActive = true
            mainLbl.textAlignment = .left
        }
        
    }
    
    @objc func pressed() {
        self.delegate?.evrAirButtonPressed()
        
    }
    
    func toggle() {
        if isOpen {
            close()
        }else {
            open()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func open() {
        isAnimated = true
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.mainLbl.alpha = 1
        }) { (_) in
            
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            var subX: CGFloat = 0
            var topX: CGFloat = 0
            if self.directions == .left {
                subX = -1 * self.openWidth
                topX = -1 * self.openWidth
            }else {
                subX = 0
                topX = self.openWidth
            }
            self.subView.frame = CGRect(x: subX,
                                        y: 0,
                                        width: self.openWidth + self.mainR * 2,
                                        height: self.frame.height)
            
            self.topView.frame = CGRect(x: topX,
                y: 0 ,
                width: self.frame.height,
                height: self.frame.height)
            /*self.frame = CGRect(x: posX,
             y: self.mainCenter.y ,
             width: 200,
             height: self.frame.height) */
        }) { (_) in
            self.isOpen = true
            self.isAnimated = false
        }
    }
    
    func close() {
        isAnimated = true
        UIView.animate(withDuration: 0.15, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.mainLbl.alpha = 0
        }) { (_) in
            
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            self.subView.frame = CGRect(x: 0 ,
                                        y: 0,
                                        width: self.mainR * 2,
                                        height: self.frame.height)
            self.topView.frame = CGRect(x: 0,
                                        y: 0 ,
                                        width: self.frame.height,
                                        height: self.frame.height)
        }) { (_) in
            self.isOpen = false
            self.isAnimated = false
        }
    }
    
}

