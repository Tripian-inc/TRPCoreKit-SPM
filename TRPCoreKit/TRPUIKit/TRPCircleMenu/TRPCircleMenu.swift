//
//  TRPCircleMenu.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 28.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//`

import Foundation
import UIKit
open class TRPCircleMenu: UIButton {
    public enum CurrentState {
        case open, close
    }
    public enum Position {
        case left, right, top, bottom
    }
    
    fileprivate var animator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6)//UIViewPropertyAnimator(duration: 0.1, curve: .easeOut)
    private var subButtons: [TRPCirleButtonPropety] = []
    private var createdSubButtons: [TRPCirleButton] = []
    private var normalIcon: UIImage?
    private var selectedIcon: UIImage?
    private var normalImageView: UIImageView?
    private var selectedImageView: UIImageView?
    private var isNormal: Bool = true
    private var containerView: UIView?
    private var darkOverlayView: UIView?
    private var subButtonsPosition: Position = .left
    public var subButtonSpace: CGFloat = 35
    private var circleR: CGFloat = 50
    
    private var currentStatus: CurrentState = .close {
        didSet {
            delegate?.circleMenu(self, changedState: currentStatus)
        }
    }
    
    private var isAnimating = false
    public weak var delegate: TRPCirleMenuDelegate?
    
    public init(frame: CGRect,
                normalIcon: UIImage?,
                selectedIcon: UIImage?,
                subButtons: [TRPCirleButtonPropety]?,
                position: Position = .left) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        self.normalIcon = normalIcon
        self.selectedIcon = selectedIcon
        self.subButtons = subButtons ?? []
        self.subButtonsPosition = position
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addTarget(self, action: #selector(self.onPressed), for: UIControl.Event.touchDown)
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        
        if let image = normalIcon {
            normalImageView = UIImageView(image: image)
            addSubview(normalImageView!)
            setCenter(imageView: normalImageView!)
        }
        if let image = selectedIcon {
            selectedImageView = UIImageView(image: image)
            addSubview(selectedImageView!)
            selectedImageView?.alpha = 0
            setCenter(imageView: selectedImageView!)
        }
    }
    
    open override func layoutSubviews() {
        if containerView == nil {
            createDarkOverlayView()
            createContainerView()
            containerView!.alpha = 0
            containerView!.isHidden = true
        }
    }
    
    @objc func onPressed() {
        animateCircleView()
    }
    
    private func animateCircleView(){
        DispatchQueue.main.async {
            if self.isAnimating == true {return}
            self.tapRotatedAnimation(0.4, isSelected: !self.isSelected)
            if self.createdSubButtons.count == 0 {
                self.createSubButtons(self.subButtons)
            }
            if self.isSelected {
                self.containerView!.alpha = 1
                self.containerView!.isHidden = false
            }
            self.addAnimation()
        }
    }
    
    private func setCenter(imageView: UIImageView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
}

// MARK: Animation For Main Button
extension TRPCircleMenu {
    fileprivate func tapRotatedAnimation(_ duration: Float, isSelected: Bool) {
        if let customNormalIconView = self.normalImageView {
            animationForImages(customNormalIconView, !isSelected, duration)
        }
        if let customSelectedIconView = self.selectedImageView {
            animationForImages(customSelectedIconView, isSelected, duration)
        }
        
        self.isSelected = isSelected
        alpha = isSelected ? 0.5 : 1
    }
    
    fileprivate func animationForImages(_ view: UIImageView, _ isShow: Bool, _ duration: Float) {
        var toAngle: Float = 180.0
        var fromAngle: Float = 0
        var fromScale = 1.0
        var toScale = 0.2
        var fromOpacity = 1
        var toOpacity = 0
        if isShow == true {
            toAngle = 0
            fromAngle = -180
            fromScale = 0.2
            toScale = 1.0
            fromOpacity = 0
            toOpacity = 1
        }
        
        let rotationAnim = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnim.duration = TimeInterval(duration)
        rotationAnim.toValue = (toAngle.degrees)
        rotationAnim.fromValue = (fromAngle.degrees)
        rotationAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.duration = TimeInterval(duration)
        fadeAnim.fromValue = fromOpacity
        fadeAnim.toValue = toOpacity
        fadeAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        fadeAnim.fillMode = CAMediaTimingFillMode.forwards
        fadeAnim.isRemovedOnCompletion = false
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.duration = TimeInterval(duration)
        scaleAnim.toValue = toScale
        scaleAnim.fromValue = fromScale
        scaleAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        view.layer.add(rotationAnim, forKey: nil)
        view.layer.add(fadeAnim, forKey: nil)
        view.layer.add(scaleAnim, forKey: nil)
    }
}

// MARK: Container view
extension TRPCircleMenu {
    
    fileprivate func createContainerView() {
        containerView = UIView(frame: CGRect.zero)
        guard let containerView = containerView else {return}
        superview?.insertSubview(containerView, belowSubview: self)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        var width: CGFloat = 240
        if UIScreen.main.bounds.width < 325.0{//Iphone 5 ve diger kucukleri icin
            width = 200
            subButtonSpace = 17
            circleR = 40
        }
        var height: CGFloat = 100
        
        switch subButtonsPosition {
        case .left:
            width = CGFloat(subButtons.count) * CGFloat(40 + subButtonSpace)
            height = frame.height
            containerView.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
            containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            break
        case .right:
            width = CGFloat(subButtons.count) * CGFloat(40 + subButtonSpace)
            height = frame.height
            containerView.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
            containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            break
        case .top:
            height = CGFloat(subButtons.count) * CGFloat(40 + subButtonSpace)
            width = frame.height
            containerView.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            break
        case .bottom:
            height = CGFloat(subButtons.count) * CGFloat(40 + subButtonSpace)
            width = frame.height
            containerView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            break
        }
        containerView.widthAnchor.constraint(equalToConstant: width + 40).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        //superview?.bringSubviewToFront(containerView)
        darkOverlayView?.bringSubviewToFront(containerView)
    }
}

// MARK: - Dark Overlay view
extension TRPCircleMenu {
    private func createDarkOverlayView() {
        darkOverlayView = UIView(frame: CGRect.zero)
        guard let darkOverlayView = darkOverlayView else {return}
        superview?.insertSubview(darkOverlayView, belowSubview: self)
        //superview?.sendSubviewToBack(darkOverlayView)
        darkOverlayView.translatesAutoresizingMaskIntoConstraints = false
        //darkOverlayView.isUserInteractionEnabled = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(darkOverlayPressed))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(darkOverlayPressed))
        let tap = UITapGestureRecognizer(target: self, action: #selector(darkOverlayPressed))
        darkOverlayView.addGestureRecognizer(pan)
        darkOverlayView.addGestureRecognizer(swipe)
        darkOverlayView.addGestureRecognizer(tap)
        tap.require(toFail: swipe)
        swipe.require(toFail: pan)
        darkOverlayView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        darkOverlayView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
    }
    
    private func updateOverlayView(){
        if self.currentStatus == .close {
            self.showDarkOverlayView()
        }else {
            self.hideDarkOverlayView()
        }
    }
    
    private func showDarkOverlayView(){
        guard let darkOverlayView = darkOverlayView else {return}
        //Burada emulatorde sorun yaratiyor ona bak
        //        superview?.bringSubviewToFront(darkOverlayView)
        //        superview?.bringSubviewToFront(containerView)
        //        superview?.bringSubviewToFront(self)
        //        containerView.sendSubviewToBack(darkOverlayView)
        //        superview?.insertSubview(darkOverlayView, belowSubview: self)
        //        darkOverlayView.bringSubviewToFront(containerView)
        darkOverlayView.layer.backgroundColor = UIColor.black.cgColor
        darkOverlayView.layer.opacity = 0.6
        darkOverlayView.isUserInteractionEnabled = true
    }
    
    private func hideDarkOverlayView(){
        guard let darkOverlayView = darkOverlayView else {return}
        darkOverlayView.layer.backgroundColor = UIColor.clear.cgColor
        darkOverlayView.layer.opacity = 0
        darkOverlayView.isUserInteractionEnabled = false
    }
    
    //MARK: - Dark Overlay Objc Funcs
    @objc func darkOverlayPressed() {
        if currentStatus == .open{
            animateCircleView()
        }
        else{
            hideDarkOverlayView()
        }
    }
}

// MARK: SubButtons
extension TRPCircleMenu {
    
    fileprivate func createSubButtons(_ buttons: [TRPCirleButtonPropety]) {
        guard let containerView = containerView else {return}
        if UIScreen.main.bounds.width < 325.0{//Iphone 5 ve digerleri
            subButtonSpace = 17
            circleR = 40
        }
        for i in 0..<buttons.count {
            //let startX: CGFloat = (containerView.frame.width - cirleR - subButtonSpace) - ((cirleR + subButtonSpace) * CGFloat(i))
            let dist = subButtonSpace == 17 ? subButtonSpace : subButtonSpace + 30
            let startX: CGFloat = self.containerView!.frame.width - dist
            let startY: CGFloat = (containerView.frame.height - circleR) / 2
            if let image = buttons[i].image {
                let btn = TRPCirleButton(frame: CGRect(x: startX, y:startY, width: circleR, height: circleR),
                                         normalImage:image,
                                         titleName: buttons[i].name)
                btn.alpha = 0
                btn.tag = i
                btn.addTarget(self, action: #selector(subButtonPressed(_:)), for: UIControl.Event.touchDown)
                containerView.addSubview(btn)
                createdSubButtons.append(btn)
            }
        }
    }
    
    @objc func subButtonPressed(_ sender: UIButton) {
        delegate?.circleMenu(self, onPress: sender, atIndex: sender.tag)
    }
    
}

extension TRPCircleMenu {
    func addAnimation() {
        DispatchQueue.main.async {
            self.isAnimating = true
            self.animator.addAnimations { [weak self] in
                guard let strongSelf = self else {return}
                strongSelf.updateOverlayView()
                if strongSelf.currentStatus == .close {
                    for i in 0..<strongSelf.createdSubButtons.count {
                        let position = (strongSelf.containerView!.frame.width - strongSelf.circleR - strongSelf.subButtonSpace) - ((strongSelf.circleR + strongSelf.subButtonSpace) * CGFloat(i))
                        strongSelf.createdSubButtons[i].transform = CGAffineTransform(translationX: -position, y: 0)
                        strongSelf.createdSubButtons[i].alpha = 1
                    }
                }else {
                    for i in 0..<strongSelf.subButtons.count {
                        strongSelf.createdSubButtons[i].transform = CGAffineTransform.identity
                        strongSelf.createdSubButtons[i].alpha = 0
                    }
                }
            }
            self.animator.addCompletion { _ in
                self.updateOverlayView()
                if self.currentStatus == .close {
                    self.currentStatus = .open
                }else {
                    self.currentStatus = .close
                    self.containerView!.alpha = 0
                    self.containerView!.isHidden = true
                }
                self.isAnimating = false
            }
            self.animator.startAnimation()
        }
    }
}



internal extension Float {
    var radians: Float {
        return self * (Float(180) / Float.pi)
    }
    
    var degrees: Float {
        return self * Float.pi / 180.0
    }
}

internal extension UIView {
    
    var angleZ: Float {
        return atan2(Float(transform.b), Float(transform.a)).radians
    }
}

