import Foundation
import MapboxMaps
import UIKit

/// Simplified annotation view for map markers
/// Shows only the order number in a 24x24 circular badge
class TRPRotaAnnotationView: UIView {

    var onTapHandler: ((String) -> Void)?
    var poiId: String?

    private let orderLabel = UILabel()
    private static let viewSize: CGFloat = 24

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.viewSize, height: Self.viewSize)
    }

    // MARK: - Initialization

    /// Initialize with order number, city index for multi-city coloring, and selection state
    init(order: Int, cityIndex: Int = 0, isSelected: Bool = false) {
        super.init(frame: CGRect(x: 0, y: 0, width: Self.viewSize, height: Self.viewSize))
        let color = ColorSet.getMapColor(cityIndex)
        setupView(order: order, color: color, isSelected: isSelected)
    }

    /// Legacy initializer for backward compatibility
    init(reuseIdentifier: String?, imageName: String?, order: Int?, isOffer: Bool = false, annotationOrder: Int = 0, isSelected: Bool = false) {
        super.init(frame: CGRect(x: 0, y: 0, width: Self.viewSize, height: Self.viewSize))
        let displayOrder = order ?? 0
        let color = ColorSet.getMapColor(annotationOrder)
        setupView(order: displayOrder, color: color, isSelected: isSelected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView(order: Int, color: UIColor = ColorSet.fg.uiColor, isSelected: Bool = false) {
        // Set content hugging to prevent expansion
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        // Circular shape
        layer.cornerRadius = Self.viewSize / 2
        clipsToBounds = true

        // Apply selected/unselected appearance
        if isSelected {
            // Selected: Solid color background, white text
            backgroundColor = color
            layer.borderWidth = 0
        } else {
            // Unselected: White background, colored border, colored text
            backgroundColor = .white
            layer.borderWidth = 2
            layer.borderColor = color.cgColor
        }

        // Order label - centered using Auto Layout
        orderLabel.translatesAutoresizingMaskIntoConstraints = false
        orderLabel.text = "\(order)"
        orderLabel.textColor = isSelected ? .white : color
        orderLabel.font = FontSet.montserratSemiBold.font(18)
        orderLabel.textAlignment = .center
        orderLabel.adjustsFontSizeToFitWidth = true
        orderLabel.minimumScaleFactor = 0.7

        addSubview(orderLabel)

        // Center label in view
        NSLayoutConstraint.activate([
            orderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            orderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            orderLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            orderLabel.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ])

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update corner radius based on actual size
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTapHandler?(poiId ?? "")
    }
}
