//
//  DynamicHeightTableView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

class DynamicHeightTableView: UITableView {

    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet{
            self.invalidateIntrinsicContentSize()
        }
    }
}
