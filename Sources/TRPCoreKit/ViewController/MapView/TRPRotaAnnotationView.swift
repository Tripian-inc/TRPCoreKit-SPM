
import Foundation
import Mapbox
import TRPUIKit
class TRPRotaAnnotationView: MGLAnnotationView {
    
    let redColor = UIColor.black.cgColor //UIColor(red: 229.0/255.0, green: 78.0/255.0, blue: 83.0/255.0, alpha: 1.0).cgColor
    let blueColor = UIColor(red: 53/255.0, green: 152/255.0, blue: 218/255.0, alpha: 1.0).cgColor
    var bgView: UIView = UIView();
    let label = UILabel()
    let cirleShape = CAShapeLayer()
    var imageName:String = ""
    var order: Int?
    var isOffer: Bool = false
    
    private var viewDidLoaded = false
    
    init(reuseIdentifier: String, imageName:String, order:Int?, isOffer: Bool = false) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.imageName = imageName
        self.order = order
        self.isOffer = isOffer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if viewDidLoaded == true {return}
        viewDidLoaded = true
        layer.cornerRadius = bounds.width / 2
        layer.backgroundColor = UIColor.clear.cgColor
        addImageView(named: imageName)
        addBGView()
        guard let order = self.order else { return }
        addLabel(text: "\(order)")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let animation = CABasicAnimation(keyPath: "ClickAnim")
        animation.duration = 0.1
        bgView.layer.borderWidth = selected ? bounds.width / 7 : 1
        bgView.layer.add(animation, forKey: "ClickAnim")
        bgView.layer.borderColor = selected ? redColor : blueColor
        label.alpha = selected ? 0.1 : 1.0
        label.layer.add(animation, forKey: "ClickAnim")
        cirleShape.fillColor = selected ? UIColor.red.cgColor : redColor
        cirleShape.lineWidth = selected ? 0 : 1
        cirleShape.add(animation, forKey: "ClickAnim")
    }
    
    private func addImageView(named: String){
        let img = TRPImageController().getImage(inFramework: named, inApp: nil) ?? UIImage()
        let imgView = UIImageView(image: img)
        
        if isOffer {
            let bgImage = UIImageView(image: UIImage(named: "offer_bg_annotation")!)
            self.addSubview(bgImage)
            self.addSubview(imgView)
            self.frame = bgImage.frame
            imgView.center = bgImage.center
        }else {
            self.addSubview(imgView)
            self.frame = imgView.frame
        }
//        addSubview(imgView)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imgView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addBGView() {
        bgView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        bgView.layer.cornerRadius = bgView.frame.width / 2
        bgView.layer.borderColor = UIColor.clear.cgColor
        bgView.layer.borderWidth = 1
        self.addSubview(bgView)
    }
    
    private func addLabel(text: String) {
        let circleRadius = 10.0
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: circleRadius/2,
                                                         y: circleRadius/2),
                                      radius: CGFloat(circleRadius),
                                      startAngle: 0,
                                      endAngle: CGFloat(Double.pi * 2),
                                      clockwise: true)
        cirleShape.path = circlePath.cgPath
        cirleShape.fillColor = UIColor(red: 44/255.0, green: 152/255.0, blue: 240/255.0, alpha: 1.0).cgColor
        //cirleShape.strokeColor = UIColor(red: 80/255.0, green: 80/255.0, blue: 80/255.0, alpha: 1.0).cgColor
        cirleShape.lineWidth = 0
        
        label.frame = CGRect(x: CGFloat( -1 * (circleRadius / 2)),
                             y: CGFloat( -1 * (circleRadius / 2)),
                             width: CGFloat(circleRadius * 2),
                             height: CGFloat(circleRadius * 2))
        label.text = text
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        
        self.layer.addSublayer(cirleShape)
        self.addSubview(label)
    }
    
}


