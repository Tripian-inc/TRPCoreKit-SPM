//
//  ActionViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

struct ActionModel {
    var title: String
    var subTitle: String?
    var items: [String]
    var buttonTitle: String
    
    init(_ title: String, _ subTitle: String? = nil, _ items: [String], _ btnTitle: String) {
        self.title = title
        self.subTitle = subTitle
        self.items = items
        self.buttonTitle = btnTitle
    }
}

@objc(SPMActionViewController)
class ActionViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomBtn: UIButton!
    var checkOrder: Int?
    var itemAction: ((_ order: Int) -> Void)?
    var btnAction: (() -> Void)?
    private var cellHeight: CGFloat = 50
    var titleLbl: UILabel = {
        var lbl = UILabel()
        lbl.font = trpTheme.font.header2
        lbl.textColor = trpTheme.color.tripianBlack
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    var titleView: UIView = {
       var view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    var subTitleLbl: UILabel = {
        var lbl = UILabel()
        lbl.font = trpTheme.font.body3
        lbl.textColor = trpTheme.color.tripianTextPrimary
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return lbl
    }()
    
    var model: ActionModel?
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height + 100)
//        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(bgPressed))
//        view.addGestureRecognizer(gesture)
        setupUI()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.containerView.transform = .identity
        }
    }
    
    @objc func bgPressed() {
        //dismiss(animated: true, completion: nil)
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 35
        guard let model = model else {return}
        titleLbl.text = model.title
        titleView.addSubview(titleLbl)
        titleLbl.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 12).isActive = true
        titleLbl.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -12).isActive = true
        titleLbl.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 0).isActive = true
        titleLbl.bottomAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 0).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stackView.addArrangedSubview(titleView)
        
        if let sub = model.subTitle {
            subTitleLbl.text = sub
            stackView.addArrangedSubview(subTitleLbl)
        }
        
        for (index, item) in model.items.enumerated() {
            let itemLbl = createItem(item, index)
            stackView.addArrangedSubview(itemLbl)
        }
        bottomBtn.setTitle(model.buttonTitle, for: .normal)
        
        addCheckView()
    }
    
    public func config(_ model: ActionModel) {
        if model.items.count > 7 {
            cellHeight = 30
        }
        self.model = model
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    private func addCheckView() {
        guard let checkIndex = checkOrder else {return}
        
        stackView.subviews.forEach { item in
            if item.tag == 300 + checkIndex {
                let img = TRPImageController().getImage(inFramework: "btn_check", inApp: nil)
                let imgView = UIImageView(image: img)
                item.addSubview(imgView)
                imgView.translatesAutoresizingMaskIntoConstraints = false
                imgView.widthAnchor.constraint(equalToConstant: 26).isActive = true
                imgView.heightAnchor.constraint(equalToConstant: 26).isActive = true
                imgView.trailingAnchor.constraint(equalTo: item.trailingAnchor, constant: -12).isActive = true
                imgView.centerYAnchor.constraint(equalTo: item.centerYAnchor).isActive = true
            }
        }
    }
    private func createItem(_ text: String, _ order: Int) -> UILabel {
        let lbl = UILabel()
        lbl.font = trpTheme.font.body1
        lbl.textColor = trpTheme.color.tripianTextPrimary
        lbl.textAlignment = .center
        lbl.tag = order
        lbl.text = text
        lbl.tag = 300 + order
        //lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.heightAnchor.constraint(equalToConstant: cellHeight).isActive = true
        let tab = UITapGestureRecognizer(target: self, action: #selector(itemPressed(_:)))
        lbl.isUserInteractionEnabled = true
        lbl.addGestureRecognizer(tab)
        
        return lbl
    }
    
    @objc func itemPressed(_ sender: UITapGestureRecognizer) {
        guard let senderView = sender.view else {return}
        dismissView { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.itemAction?(senderView.tag - 300)
        }
    }
    
    @IBAction func bottomButtonPressed(_ sender: Any) {
        btnAction?()
    }
    
    
    
    public func dismissView(completion: ((_ status: Bool) -> Void)?) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
        } completion: { _ in
            self.dismiss(animated: false) {
                completion?(true)
            }
        }
    }
    
}
