//
//  RequirementFieldSubView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-04.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

class RequirementFieldSubView: UIView {
    
    var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = subTitle ?? ""
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    lazy var inputText: UITextView = {
        var textView = UITextView()
        textView.text = !selectedContent.isEmpty ? selectedContent : placeHolder
        textView.textColor = UIColor.lightGray
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.layer.cornerRadius = 10
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        return textView
    }()
    
    lazy var label: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.layer.cornerRadius = 10
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = !selectedContent.isEmpty ? selectedContent : placeHolder
        let gesture = UITapGestureRecognizer(target: self, action: #selector(labelPressed))
        label.addGestureRecognizer(gesture)
        label.isUserInteractionEnabled = true
        label.textColor = !selectedContent.isEmpty ? UIColor.black : UIColor.lightGray
        return label
    }()
    
    
    private var title: String
    private var subTitle: String?
    private var placeHolder: String
    private var numberOfLine: Int
    public var isOpenAction: Bool = false
    public var selectedContent: String = "" {
        didSet {
            label.text = !selectedContent.isEmpty ? selectedContent : placeHolder
            label.textColor = !selectedContent.isEmpty ? UIColor.black : UIColor.lightGray
        }
    }
    public var selectedAction: (() -> Void)?
    
    init(title: String, subTitle: String? = nil, placeHolder: String, numberOfLine: Int, openAction: Bool = false) {
        self.title = title
        self.subTitle = subTitle
        self.placeHolder = placeHolder
        self.numberOfLine = numberOfLine
        self.isOpenAction = openAction
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupView() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            label.heightAnchor.constraint(equalToConstant: 30)
        ])

        stackView.addArrangedSubview(titleLabel)
        if subTitle != nil {
            stackView.addArrangedSubview(subTitleLabel)
        }
        if !isOpenAction {
            stackView.addArrangedSubview(inputText)
        }else {
            stackView.addArrangedSubview(label)
        }
        inputText.delegate = self
    }
    
    
    @objc func labelPressed() {
        selectedAction?()
    }
    
    public func getSelectedValue() -> String? {
        
        return selectedContent
    }
}

extension RequirementFieldSubView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeHolder {
            textView.text = ""
            textView.textColor = UIColor.black
        }else if textView.text == "" {
            textView.text = placeHolder
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            selectedContent = ""
            textView.text = placeHolder
            textView.textColor = UIColor.lightGray
        }else {
            selectedContent = textView.text
        }
    }
    
}


