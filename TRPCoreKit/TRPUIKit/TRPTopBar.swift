//
//  TRPTopBar.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 9.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
protocol TopBarDelegate: AnyObject {
    func topBar(_ topBar:TRPTopBar, buttonPressed: UIButton)
}


public class TRPTopBar: UIView {
    
    public typealias ButtomSpacing = (horizontalSpace:CGFloat, bottom:CGFloat)
    
    public enum ButtonPosition {
        case right, left
    }
    
    // TODO: - Fetch from design
    public var buttomSpacing: ButtomSpacing = ButtomSpacing(8,8)
    public let height: CGFloat = 80.0
    public let labelWidth = 100
    public let labelHeight = 40
    public let buttonHeight:CGFloat = 44
    public let buttonWidth:CGFloat = 44
    //weak var delegate:TopBarDelegate?
    var closeButton: UIButton?
    var titleLabel : UILabel?
    var closeButtonPosition = ButtonPosition.right
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        start()
    }
    
    public init(viewControllerFrame: CGRect) {
        super.init(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: viewControllerFrame.width, height: height))
        start()
    }
    
    required public init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        start()
    }
    
    //override func layoutSubviews() {
    func start(){
        self.backgroundColor = UIColor.black
        addTitle()
    }
    
    public func addButton(_ button: UIButton, position: ButtonPosition ) {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        if position == .left {
            button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: buttomSpacing.horizontalSpace).isActive = true
            
        }else {
            button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * buttomSpacing.horizontalSpace).isActive = true
        }
        button.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * buttomSpacing.bottom).isActive = true
        //button.addTarget(self, action: #selector(closeButtonPressed(sender:)), for: .touchUpInside)
    }
    
    
    
    private func addTitle() {
        titleLabel = UILabel()
        addSubview(titleLabel!)
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        //titleLabel?.widthAnchor.constraint(equalToConstant: 100).isActive = true
        titleLabel?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60).isActive = true
        titleLabel?.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60).isActive = true
        titleLabel?.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
//        titleLabel?.text = "My Trip"
        titleLabel?.font = UIFont.systemFont(ofSize: 18)
        titleLabel?.textColor = UIColor.white
        titleLabel?.textAlignment = .center
    }
    
    
    public func setTitle(_ title:String) {
        self.titleLabel?.text = title
    }
    
    public func setTitleColor(_ color: UIColor) {
        titleLabel?.textColor = color
    }
    
    public func setBgColor(_ color: UIColor) {
        backgroundColor = color
    }
}
