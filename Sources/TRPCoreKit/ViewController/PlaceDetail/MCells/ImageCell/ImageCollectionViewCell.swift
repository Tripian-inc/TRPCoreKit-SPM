//
//  ImageCollectionViewCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/31/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit

final class ImageCollectionViewCell: UICollectionViewCell{
    
    public var item: PagingImage? = nil {
        didSet {
            setImage()
            setPictureOwner()
        }
    }
    
    lazy var topImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = TRPColor.darkGrey
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 0
        if let image = TRPImageController().getImage(inFramework: "image_loading", inApp: TRPAppearanceSettings.PoiDetail.imageLoadingImage) {
            imageView.image = image
        }
        return imageView
    }()
    
    lazy var pictureOwnerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.textColor = UIColor.white
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowOpacity = 0.9
        lbl.layer.shadowOffset = .zero
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
        layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp(){
        setImageView()
        setImageOwner()
    }
    
    fileprivate func setImageView() {
        addSubview(topImageView)
        topImageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width).isActive = true
        topImageView.heightAnchor.constraint(equalToConstant: self.contentView.frame.height).isActive = true
        topImageView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    }
    
    fileprivate func setImageOwner() {
        addSubview(pictureOwnerLabel)
        pictureOwnerLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
        pictureOwnerLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pictureOwnerLabel.bottomAnchor.constraint(equalTo: topImageView.bottomAnchor, constant: -90).isActive = true
    }
    
}

//MARK: Set Image & Pic Owner
extension ImageCollectionViewCell{
    private func setImage(){
        guard let item = item else {return}
        guard let imageUrl = item.imageUrl else {return}
        if let url = URL(string: imageUrl){
            topImageView.sd_setImage(with: url, placeholderImage: nil)
        }
    }
    
    private func setPictureOwner(){
        guard let item = item else {return}
        let pictureOwner = item.picOwner
        if let name = pictureOwner?.title {
            pictureOwnerLabel.text = "© \(name)"
            pictureOwnerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(picterOwnerLblPressed)))
            pictureOwnerLabel.isUserInteractionEnabled = true
        }
    }
    
    /// Url String okunabilir hale getiriyor.
    /// - Parameter text: Url formatındaki String
    func htmlToString(_ text:String) -> String? {
        let data = Data(text.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributedString.string
        }
        return nil
    }
    
    
    @objc func picterOwnerLblPressed() {
        guard let item = item else {return}
        guard let link = item.picOwner?.url else {return}
        
        if let url = URL(string: link) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
