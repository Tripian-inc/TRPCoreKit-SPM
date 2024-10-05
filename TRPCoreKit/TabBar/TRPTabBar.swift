//
//  TRPTabBar.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 26.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol TRPTabBarDelegate:AnyObject {
    func trpTabBarPressed(_ button: TRPTabBarItem)
}

final class TRPTabBar: UIView {
    
    private var isLayoutLoaded = false
    public weak var delegate: TRPTabBarDelegate?
    private let bigButtonWH: CGFloat = 70
    
    lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 3
        let mainWidth:CGFloat = frame.width
        let mainHeight:CGFloat = 100
        var mainR: CGFloat = 80
        let startX:CGFloat = mainWidth / 2 - mainR / 2
        let ovalPath = UIBezierPath()
        ovalPath.move(to: CGPoint(x: startX + 100 * mainR / 100 , y: 0))
        ovalPath.addCurve(to: CGPoint(x: startX + 50 * mainR / 100, y: 50 * mainR / 100),
                          controlPoint1: CGPoint(x: startX + 100 * mainR / 100, y: 27.61 * mainR / 100),
                          controlPoint2: CGPoint(x: startX + 77.61 * mainR / 100, y: 50 * mainR / 100))
        ovalPath.addCurve(to: CGPoint(x: startX + 0 * mainR / 100, y: 0 * mainR / 100),
                          controlPoint1: CGPoint(x: startX + 22.39 * mainR / 100, y: 50 * mainR / 100),
                          controlPoint2: CGPoint(x: startX + 0 * mainR / 100, y: 27.61 * mainR / 100))
        
        ////////////////////////////
        ovalPath.addLine(to: CGPoint(x: 0, y: 0))
        ovalPath.addLine(to: CGPoint(x: 0, y: mainHeight))
        ovalPath.addLine(to: CGPoint(x: mainWidth, y: mainHeight))
        ovalPath.addLine(to: CGPoint(x: mainWidth, y: 0))
        ovalPath.close()
        UIColor.gray.setFill()
        ovalPath.fill()
        
        let semiCirleLayer = CAShapeLayer()
        semiCirleLayer.path = ovalPath.cgPath
        semiCirleLayer.fillColor = UIColor.white.cgColor
        view.layer.addSublayer(semiCirleLayer)
 
        return view
    }()
    
    var barButtomItems: [TRPTabBarItem] = []
    
    var mainHeight: CGFloat = 50
    
    init(frame: CGRect, mainHeight: CGFloat) {
        self.mainHeight = mainHeight
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0)
        drawBg()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        if !isLayoutLoaded {
            isLayoutLoaded.toggle()
            addBarButtomItems(barButtomItems)
        }
    }

}

extension TRPTabBar {
    
    fileprivate func drawBg() {
        addSubview(bgView)
        bgView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bgView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bgView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bgView.heightAnchor.constraint(equalToConstant: mainHeight).isActive = true
    }
    
}


extension TRPTabBar {

    @objc func buttonsPerssed(_ sender: UILongPressGestureRecognizer) {
        guard let view = sender.view else {return}
        
        if sender.state == .began {
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut,
                           animations: {
                            view.transform = CGAffineTransform(scaleX: 1.1,y: 1.1);
            }) { (_) in}
            
        }else if sender.state == .ended{
            UIView.animate(withDuration: 0.15, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                view.transform = CGAffineTransform(scaleX: 1,y: 1);
            }) { [weak self](_) in
                guard let strongSelf = self else {return}
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    strongSelf.delegate?.trpTabBarPressed(strongSelf.barButtomItems[view.tag])
                })
            }
        }
    }
    
    fileprivate func addBarButtomItems(_ items: [TRPTabBarItem]){
        for (index,btn) in items.enumerated() {
            let itemBtn = createButton(btn)
            addSubview(itemBtn)
            itemBtn.tag = index
            itemBtn.isUserInteractionEnabled = true
            //itemBtn.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(buttonPressed(_:))))
            let press = UILongPressGestureRecognizer(target: self, action: #selector(buttonsPerssed(_:)))
            press.minimumPressDuration = 0.0
            itemBtn.addGestureRecognizer(press)
            
            let position = getPosition(index: index, totalItem:items.count)
            let nextPosition = getPosition(index: index + 1, totalItem:items.count)
            if btn.style == .normal {
                itemBtn.frame = CGRect(x: position.x,
                                       y: position.y,
                                       width: getWidth(items.count),
                                       height: 50)
            }else {
                
               
                let reCalculateX = (nextPosition.x - position.x) / 2 + position.x - (bigButtonWH / 2)
                itemBtn.frame = CGRect(x: reCalculateX ,
                                       y: position.y - 35,
                                       width: bigButtonWH,
                                       height: bigButtonWH)
            }
        }
    }
    
    func getPosition(index: Int, totalItem:Int) -> (x:CGFloat, y:CGFloat) {
        let mainArea = frame.width - 16
        let x = mainArea / CGFloat(totalItem) * CGFloat(index) + 8
        let y: CGFloat = self.frame.height - mainHeight
        return (x,y)
    }
    
    func getWidth(_ totalItem:Int) -> CGFloat {
        let mainArea = frame.width - 16
        return mainArea / CGFloat(totalItem)
    }
    
    func createButton(_ item: TRPTabBarItem) -> UIView{
        if item.style == .normal {
            return normalButton(item: item)
        }
        return bigButton(item: item)
    }
    
    func normalButton(item: TRPTabBarItem) -> UIView {
        let btn = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        //btn.backgroundColor = UIColor.blue
        let img = UIImageView(image: item.defaultImage)
        btn.addSubview(img)
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.centerXAnchor.constraint(equalTo: btn.centerXAnchor).isActive = true
        img.centerYAnchor.constraint(equalTo: btn.centerYAnchor, constant: -6).isActive = true
        img.widthAnchor.constraint(equalToConstant: 25).isActive = true
        img.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        let title = UILabel(frame: CGRect.zero)
        btn.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: btn.leadingAnchor).isActive = true
        title.trailingAnchor.constraint(equalTo: btn.trailingAnchor).isActive = true
        title.topAnchor.constraint(equalTo: img.bottomAnchor, constant: 2).isActive = true
        title.text = item.title
        title.textAlignment = .center
        title.font = UIFont.systemFont(ofSize: 10)
        return btn
    }
    
    
    func bigButton(item: TRPTabBarItem) -> UIView {
        
        let btn = UIView(frame: CGRect(x: 0, y: 0, width: bigButtonWH, height: bigButtonWH))
        btn.layer.cornerRadius = bigButtonWH / 2
        btn.backgroundColor =  UIColor.init(red: 44/255, green: 152/255, blue: 240/255, alpha: 1)
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = .zero
        btn.layer.shadowRadius = 3
        
        //btn.backgroundColor = UIColor.blue
        let img = UIImageView(image: item.defaultImage)
        btn.addSubview(img)
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.centerXAnchor.constraint(equalTo: btn.centerXAnchor).isActive = true
        img.centerYAnchor.constraint(equalTo: btn.centerYAnchor, constant: 0).isActive = true
        img.widthAnchor.constraint(equalToConstant: 26).isActive = true
        img.heightAnchor.constraint(equalToConstant: 26).isActive = true
        
        return btn
    }
}

