//
//  TRPMapTopBar.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 20.12.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
import UIKit
public protocol TRPMapTopBarDelegate: AnyObject {
    func trpMapTopBarBackPressed(_ mapTopBar: TRPMapTopBar)
    func trpMapTopBarChangeDayPressed(_ mapTopBar: TRPMapTopBar, dayNum: Int, text: String?)
    func trpMapTopBarSearchPressed(_ mapTopBar: TRPMapTopBar)
}


public class TRPMapTopBar: UIView {
    
    private var dayId: Int = 0
    
    lazy private var backButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        //btn.setImage(UIImage(named: "right-arrow_small"), for: .normal)
        btn.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        return btn
    }()
    
    lazy private var dailyButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Day 1 ", for: .normal)
        btn.setTitleColor(TRPColor.darkGrey, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        //btn.contentHorizontalAlignment = .left
        btn.addTarget(self, action: #selector(changeDayPressed(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy private var searchButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(searchPressed), for: .touchUpInside)
        return btn
    }()
    
    lazy private var lineView:UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = TRPColor.lightGrey
        return view
    }()
    
    lazy private var lineView2:UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = TRPColor.lightGrey
        return view
    }()
    
    public weak var delegate: TRPMapTopBarDelegate?
    
    override public init(frame: CGRect ) {
        super.init(frame: frame)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setSearchIcon(_ image: UIImage) {
        //UIImage(named: "search_icon_pink")
        searchButton.setImage(image, for: .normal)
    }
    
    public func setBackIcon(_ image: UIImage) {
        //UIImage(named: "right-arrow_small")
        backButton.setImage(image, for: .normal)
    }
    
    public func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        layer.masksToBounds = false
        
        addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -2).isActive = true
        backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        addSubview(searchButton)
        searchButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        searchButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        addSubview(dailyButton)
        dailyButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        dailyButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        dailyButton.leadingAnchor.constraint(equalTo: self.backButton.trailingAnchor, constant: 8).isActive = true
        dailyButton.trailingAnchor.constraint(equalTo: self.searchButton.leadingAnchor, constant: -8).isActive = true
        
        addSubview(lineView2)
        lineView2.topAnchor.constraint(equalTo: self.topAnchor, constant: 6).isActive = true
        lineView2.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6).isActive = true
        lineView2.widthAnchor.constraint(equalToConstant: 1).isActive = true
        lineView2.leadingAnchor.constraint(equalTo: self.backButton.trailingAnchor, constant: -4).isActive = true
    }
    
    public func setDailyText(dayNum: Int? = nil, buttonText: String? = nil) {
        var text = ""
        if let t = buttonText {
            text = t
        }else if let dayNum = dayNum{
            text = "Day \(dayNum)"
        }
        dailyButton.setTitle(text, for: UIControl.State.normal)
    }
    
    override public func layoutSubviews() {
        commonInit()
    }
    
    @objc private func backPressed(){
        delegate?.trpMapTopBarBackPressed(self)
    }
    
    @objc private func searchPressed(){
        delegate?.trpMapTopBarSearchPressed(self)
    }
    
    @objc private func changeDayPressed(_ sender: UIButton){
        delegate?.trpMapTopBarChangeDayPressed(self, dayNum: dayId, text: sender.titleLabel?.text)
    }
    
    deinit {
        print("TRMapTopBar deinit")
    }
    
}
