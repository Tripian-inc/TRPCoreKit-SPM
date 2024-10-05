//
//  TRPMomentumListView.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 2.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public class TRPMomentumListView: UIView {
    
    private lazy var dragableArea: UIView = {
        let dragabel = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: tapDragableSpace))
        dragabel.backgroundColor = UIColor.clear
        return dragabel
    }()
    
    private lazy var topGraficView: UIView = {
        let width: CGFloat = 50
        let lineView = UIView(frame: CGRect(x: (self.frame.width - width) / 2,
                                            y: 10,
                                            width: width,
                                            height: 3))
        lineView.backgroundColor = TRPColor.lightGrey
        lineView.layer.cornerRadius = 2
        return lineView
    }()
    
    private lazy var titleLabel: UILabel = {
        let lbl = UILabel(frame: CGRect(x: 0, y: 20, width: self.frame.width, height: 20))
        lbl.text = "Recommended Places"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textAlignment = .center
        lbl.textColor = TRPColor.darkGrey
        return lbl
    }()
    
    private var bottomPosition: CGFloat {
        get {
            let parentHeight = parentView?.height ?? 600
            return parentHeight - tapDragableSpace - startPositionY
        }
    }
    
    private var tapDragableSpace: CGFloat = 55
    private var parentView:CGRect?
    public var horizontalSpace:CGFloat = 10
    private var startPositionY: CGFloat = 55
    private var tableView: MovementList?
    //FOR PAN ANIM
    private let panRecognzier = InstantPanGestureRecognizer()
    var animation = UIViewPropertyAnimator();
    var isOpen = false
    private var closedTransform = CGAffineTransform.identity
    private var animationProgress: CGFloat = 0;
    //
    
    public init(parentView:CGRect) {
        let rect = CGRect(x: horizontalSpace,
                          y: startPositionY,
                          width: parentView.width - horizontalSpace * 2,
                          height: parentView.height - startPositionY + 40)
        
        super.init(frame: rect)
        self.parentView = parentView
        sharedInit()
    }
    
    public func addList(_ data: [String]) {
        if tableView != nil {
            tableView?.appendData(data)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sharedInit() {
        self.layer.cornerRadius = 30
        self.backgroundColor = UIColor.white
        self.addSubview(dragableArea)
        self.addSubview(titleLabel)
        self.addSubview(topGraficView)
        closedTransform = CGAffineTransform(translationX: 0, y: self.frame.height - startPositionY * 2)
        transform = closedTransform
        addTableView()
        addPanRecognizer()
    }
}

//Add Listview
extension TRPMomentumListView {
    
    fileprivate func addTableView(){
        tableView = MovementList(frame: CGRect(x: 0,
                                               y: tapDragableSpace,
                                               width: self.frame.width,
                                               height: self.frame.height - tapDragableSpace))
        self.addSubview(tableView!)
    }
    
}

//Pan Animation
extension TRPMomentumListView {
    
    fileprivate func addPanRecognizer() {
        panRecognzier.addTarget(self, action: #selector(addPanned(recognizer:)))
        dragableArea.addGestureRecognizer(panRecognzier)
    }
    
    func startAnimatorIfNeeded() {
        if animation.isRunning {return}
        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: 0.4, dy: 0.4))
        animation = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
        //animation = UIViewPropertyAnimator(duration: 10, curve: .easeIn)
        animation.addAnimations {
            self.transform = self.isOpen ? self.closedTransform : .identity
        }
        animation.addCompletion { position in
            if position == .end { self.isOpen = !self.isOpen }
        }
        animation.startAnimation()
    }
    
    @objc func addPanned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startAnimatorIfNeeded()
            animation.pauseAnimation()
            animationProgress = animation.fractionComplete
            break
        case .ended, .cancelled:
            let yVelocity = recognizer.velocity(in: self).y
            let shouldClose = yVelocity > 0 // todo: should use projection instead
            if yVelocity == 0 {
                animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            if isOpen {
                if !shouldClose && !animation.isReversed { animation.isReversed = !animation.isReversed }
                if shouldClose && animation.isReversed { animation.isReversed = !animation.isReversed }
            } else {
                if shouldClose && !animation.isReversed { animation.isReversed = !animation.isReversed }
                if !shouldClose && animation.isReversed { animation.isReversed = !animation.isReversed }
            }
            let fractionRemaining = 1 - animation.fractionComplete
            let distanceRemaining = fractionRemaining * closedTransform.ty
            if distanceRemaining == 0 {
                animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            let relativeVelocity = min(abs(yVelocity) / distanceRemaining, 30)
            let timingParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: CGVector(dx: relativeVelocity, dy: relativeVelocity))
            let preferredDuration = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters).duration
            let durationFactor = CGFloat(preferredDuration / animation.duration)
            animation.continueAnimation(withTimingParameters: timingParameters, durationFactor: durationFactor)
            break
        case .changed:
            var fraction = -recognizer.translation(in: self).y / closedTransform.ty
            if isOpen { fraction *= -1 }
            if animation.isReversed { fraction *= -1 }
            animation.fractionComplete = fraction + animationProgress
            break
        default: break
        }
        
    }
    
    
}
