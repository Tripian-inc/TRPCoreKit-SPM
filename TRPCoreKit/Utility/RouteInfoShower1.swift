//
//  RouteInfoShower1.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 7.10.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class RouteInfoShower1: UIView {
    
    public enum Status {
        case opened(positionY: CGFloat), closed(positionY: CGFloat), animating(positionY: CGFloat)
        func get() -> CGFloat {
            switch self {
            case .opened(let positionY):
                return positionY
            case .closed(let positionY):
                return positionY
            case .animating(let positionY):
                return positionY
            }
        }
    }
    
    private var handler: ((_ status: RouteInfoShower1.Status) -> Void)?
    
    private var animationPosY: CGFloat = 70
    
    private var arrivingTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var totalWalkingTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
     
    private var distanceLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var currentPosition = Status.closed(positionY: 0) {
        didSet {
            self.handler?(currentPosition)
        }
    }
    
    let min: Int
    let meters: Int
    let arrivalHours:String
    
    init(frame:CGRect, arrivalHours:String, min:Int, meters:Int) {
        self.min = min
        self.meters = meters
        self.arrivalHours = arrivalHours
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var tf = false
    override func layoutSubviews() {
        if !tf {
            tf.toggle()
            drawView()
            animationPosY = frame.height + 20
            startAnimation()
            startTimer()
        }
        roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
    }
    
    func startAnimation() {
        
        transform = CGAffineTransform(translationX: 0, y: -1 * animationPosY)
        UIView.animate(withDuration: 0.8, animations: { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.transform = CGAffineTransform.identity
            //strongSelf.currentPosition = Status.animating(positionY: strongSelf.animationPosY)
        }) { [weak self] (_) in
            guard let strongSelf = self else {return}
            strongSelf.transform = CGAffineTransform.identity
            strongSelf.currentPosition = .opened(positionY:strongSelf.animationPosY)
        }
    }
    
    func startTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.removeAnimation()
        }
    }
    
    func removeAnimation() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.transform = CGAffineTransform(translationX: 0, y: -1 * strongSelf.animationPosY)
        }) { [weak self] (_) in
            guard let strongSelf = self else {return}
            strongSelf.transform = CGAffineTransform(translationX: 0, y: -1 * strongSelf.animationPosY)
            strongSelf.currentPosition = .closed(positionY:0)
            strongSelf.removeFromSuperview()
        }
    }
    
    func drawView() {
        let spaceX: CGFloat = 32
        backgroundColor = UIColor.white
        
        arrivingTimeLabel.attributedText = createNewText(upperText: arrivalHours, bottomText: "arrival")
        
        let hourMin = min.minutesToHoursMinutes()
        if hourMin.hours == 0 {
            totalWalkingTimeLabel.attributedText = createNewText(upperText: "\(min)", bottomText: "min")
        }else {
            totalWalkingTimeLabel.attributedText = createNewText(upperText: "\(hourMin.hours):\(hourMin.leftMinutes)", bottomText: "hrs")
        }
        
        let readable = ReadableDistance.calculate(distance: Float(meters), time: 0)
        
        if meters > 1000 {
            distanceLabel.attributedText = createNewText(upperText: "\(readable.distance)", bottomText: "km")
        }else {
            distanceLabel.attributedText = createNewText(upperText: "\(meters)", bottomText: "m")
        }
    
        addSubview(arrivingTimeLabel)
        arrivingTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        arrivingTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spaceX).isActive = true
        
        addSubview(totalWalkingTimeLabel)
        totalWalkingTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        totalWalkingTimeLabel.leadingAnchor.constraint(equalTo: arrivingTimeLabel.trailingAnchor , constant: spaceX).isActive = true
        
        addSubview(distanceLabel)
        distanceLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        distanceLabel.leadingAnchor.constraint(equalTo: totalWalkingTimeLabel.trailingAnchor, constant: spaceX).isActive = true
    }
    
    private func createNewText(upperText: String, bottomText:String) -> NSMutableAttributedString{
        let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold),
                                  NSAttributedString.Key.foregroundColor:UIColor.darkGray]
        let mainAttribute = NSMutableAttributedString(string: upperText, attributes: typeAttributeStyle)
        
        let subTypeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        let subTypeAttribute = NSMutableAttributedString(string: "\n\(bottomText)", attributes: subTypeAttributeStyle)
        mainAttribute.append(subTypeAttribute)
        return mainAttribute
    }
    
    public func setHandler(_ handler: @escaping ((_ status: RouteInfoShower1.Status) -> Void) ) {
        self.handler = handler
    }
    
}
