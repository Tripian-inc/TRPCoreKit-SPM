//
//  SelectTravelerCountVM.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 11.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation


protocol SelectTravelerCountVMDelegate: ViewModelDelegate {
    func adultCountChanged(count: String)
    func childCountChanged(count: String)
}

public class SelectTravelerCountVM {
    public var adultCount: Int = 1 {
        didSet {
            delegate?.adultCountChanged(count: "\(adultCount)")
        }
    }
    public var childrenCount: Int = 0{
        didSet {
            delegate?.childCountChanged(count: "\(childrenCount)")
        }
    }
    
    weak var delegate: SelectTravelerCountVMDelegate?
    
    public func decreaseAdultCount() {
        if adultCount <= 1 {
            return
        }
        adultCount -= 1
    }
    
    public func decreaseChildrenCount() {
        if childrenCount == 0 {
            return
        }
        childrenCount -= 1
    }
    
    public func increaseAdultCount() {
        adultCount += 1
    }
    
    public func increaseChildrenCount() {
        childrenCount += 1
    }
    
    func setupView() {
        delegate?.adultCountChanged(count: "\(adultCount)")
        delegate?.childCountChanged(count: "\(childrenCount)")
    }
}
