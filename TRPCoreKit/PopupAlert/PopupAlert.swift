//
//  PopupAlert.swift
//  CruiseGenie
//
//  Created by Cem Çaygöz on 28.12.2021.
//

import UIKit

protocol PopupAlertDelegate: AnyObject {
    func closedPopup()
}
@objc(SPMPopupAlert)
class PopupAlert: UIViewController {
    @IBOutlet weak var contentLbl: UILabel!
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var button: TRPBtnPopup!
    @IBOutlet weak var btnConfirm: TRPBtnPopup!
    @IBOutlet weak var btnCancel: TRPBtnPopupCancel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var stackConfirm: UIStackView!
    @IBOutlet weak var subContentLbl: UILabel!
    
    var btnConfirmAction: (() -> Void)?
    var btnCancelAction: (() -> Void)?
    public var delegate: PopupAlertDelegate?
    
    private var contentTitle: String = ""
    private var subContentTitle: String = ""
    private var message: String?
    private var attributedMessage: NSAttributedString?
    private var btnTitle: String = "OK"
    private var btnCancelTitle: String = "Cancel"
    private var forOneButton = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        titleLbl.setFontColor(font: FontSet.montserratBold.font(16), color: ColorSet.primaryText.uiColor)
        contentLbl.setFontColor(font: FontSet.montserratMedium.font(14), color: ColorSet.primaryText.uiColor)
        subContentLbl.setFontColor(font: FontSet.montserratRegular.font(16), color: ColorSet.primaryText.uiColor)
        bgView.backgroundColor = trpTheme.color.textBody.withAlphaComponent(0.45)

        self.bgView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tappedBg)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupView()
    }
    
    func setupView() {
//        contentLbl.textColor = appTheme.color.text_grey
        
        if message?.contains("</") == true {
            contentLbl.attributedText = message?.htmlToAttributedString
        } else {
            contentLbl.text = message
        }
        titleLbl.isHidden = contentTitle.isEmpty
        titleLbl.text = contentTitle
        
        stackConfirm.isHidden = forOneButton
        button.isHidden = !forOneButton
        
        btnConfirm.setTitle(btnTitle)
        btnCancel.setTitle(btnCancelTitle)
        button.setTitle(btnTitle)
        
        btnConfirm.makePositiveConfirmBtn()
        if let attributedMessage = self.attributedMessage {
            contentLbl.attributedText = attributedMessage
        }
        subContentLbl.isHidden = subContentTitle.isEmpty
        subContentLbl.text = subContentTitle
    }
    @IBAction func okAction(_ sender: Any) {
        btnConfirmAction?()
        closeSelf()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        btnCancelAction?()
        closeSelf()
    }
    @IBAction func buttonAction(_ sender: Any) {
        closeSelf()
    }
    
    public func show() {
        guard let holdingView = UIApplication.getTopViewController() else {return}
        holdingView.present(self, animated: false, completion: nil)
    }
    
    public func config(title: String = "", message: String, subContent: String = "", btnTitle: String? = nil) {
        self.contentTitle = title
        self.message = message
        self.subContentTitle = subContent
        if btnTitle != nil {self.btnTitle = btnTitle!}
        
    }
    
    public func configForConfirm(title: String = "", message: String, btnTitle: String, btnCancelTitle: String = "Cancel", attributedMessage: NSAttributedString? = nil, btnConfirmAction: (() -> Void)?, btnCancelAction: (() -> Void)? = nil) {
        forOneButton = false
        self.contentTitle = title
        self.message = message
        self.btnTitle = btnTitle
        self.btnCancelTitle = btnCancelTitle
        self.btnConfirmAction = btnConfirmAction
        self.btnCancelAction = btnCancelAction
        self.attributedMessage = attributedMessage
    }
    
    @objc func tappedBg() {
        closeSelf()
    }
    
    public func closeSelf() {
        self.delegate?.closedPopup()
        self.dismiss(animated: true, completion: nil)
    }
}

@objc(SPMTRPBtn)
class TRPBtn: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    fileprivate func setupUI() {
        backgroundColor = ColorSet.primary.uiColor
        layer.cornerRadius = 26
        setTitleColor(.white, for: .normal)
        titleLabel?.font = FontSet.montserratSemiBold.font(16)
        tintColor = .white
    }
    
    func setImageAndTitle(image:UIImage?, title: String, color: UIColor? = nil, font: UIFont? = nil, semantic: UISemanticContentAttribute = .forceRightToLeft) {
        setImage(image, for: .normal)
        semanticContentAttribute = semantic

        if #available(iOS 15.0, *) {
            configuration?.imagePadding = 6
        } else {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        }
        setTitle(title, color: color, font: font)
    }
    func setTitle(_ title: String, color: UIColor? = nil, font: UIFont? = nil) {
        setTitle(title, for: .normal)
        
        if let color = color {
            setTitleColor(color, for: .normal)
        }
        
        if let font = font {
            titleLabel?.font = font
        }
    }
}

@objc(SPMTRPBtnPopup)
class TRPBtnPopup: TRPBtn {
    
    fileprivate override func setupUI() {
        super.setupUI()
        layer.cornerRadius = 20
        setTitleColor(.white, for: .normal)
//        tintColor = appTheme.color.white
    }
    
    func makePositiveConfirmBtn() {
        backgroundColor = ColorSet.primary.uiColor
    }
}

@objc(SPMTRPBtnPopupCancel)
class TRPBtnPopupCancel: TRPBtnPopup {
    
    fileprivate override func setupUI() {
        super.setupUI()
        backgroundColor = .white
        layer.borderWidth = 1.5
        layer.borderColor = ColorSet.primary.uiColor.cgColor
        setTitleColor(ColorSet.primary.uiColor, for: .normal)
//        tintColor = appTheme.color.white
    }
}

class TRPBtnSmall: TRPBtn {
    
    fileprivate override func setupUI() {
        super.setupUI()
        layer.cornerRadius = 15
        setTitleColor(.white, for: .normal)
        titleLabel?.font = trpTheme.font.semiBold12
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
//        tintColor = appTheme.color.white
    }
}
