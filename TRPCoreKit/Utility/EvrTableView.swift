//
//  EvrTableView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
public protocol EvrTableViewDelegate: AnyObject {
    func evrTableViewLabelClicked()
}
@objc(SPMEvrTableView)
public class EvrTableView: UITableView {
    
    public weak var emptyDelegate: EvrTableViewDelegate?
    private enum status {
        case show, hidden
    }
    private var isAdded = false
    public var emptyTextStartY: CGFloat = 60
    
    
    public var isHiddenEmptyText: Bool = false {
        didSet {
            emptyText.isHidden = isHiddenEmptyText
        }
    }
    
    
    
    lazy var emptyText:UILabel = {
        var txt = UILabel()
        txt.text = ""
        txt.textColor = UIColor.darkGray
        txt.font = UIFont.systemFont(ofSize: 16)
        txt.textAlignment = .center
        txt.numberOfLines = 0
        txt.translatesAutoresizingMaskIntoConstraints = false
        let tab = UITapGestureRecognizer(target: self, action: #selector(labelClicked))
        txt.addGestureRecognizer(tab)
        txt.isUserInteractionEnabled = true
        return txt
    }()
    
    @objc func labelClicked() {
        emptyDelegate?.evrTableViewLabelClicked()
    }
    
    public func setEmptyText(_ attribute: NSMutableAttributedString) {
        emptyText.attributedText = attribute
        openCloseEmptyText(.show)
    }
    
    public func setEmptyText(_ str: String) {
        emptyText.text = str
        openCloseEmptyText(.show)
    }
    
    private func openCloseEmptyText(_ status:EvrTableView.status) {
        if status == .show {
            if isAdded {
                emptyText.removeFromSuperview()
            }
            addSubview(emptyText)
            isAdded = true
            emptyText.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            emptyText.topAnchor.constraint(equalTo: self.topAnchor, constant: emptyTextStartY).isActive = true
            emptyText.widthAnchor.constraint(equalTo: widthAnchor, constant: -48).isActive = true
            emptyText.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }else {
            if isAdded {
                emptyText.removeFromSuperview()
                isAdded = false
            }
        }
    }
    
    public override func reloadData() {
        super.reloadData()
        if self.visibleCells.count > 0 {
            openCloseEmptyText(.hidden)
        }else {
            openCloseEmptyText(.show)
        }
    }
    
    
}
