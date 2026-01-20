//
//  TimelinePoiDetailViewController.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Split into extensions and separate files:
//  Extensions:
//  - TimelinePoiDetailViewController+Setup.swift (Setup methods, content configuration, map setup)
//  - TimelinePoiDetailViewController+CollectionView.swift (UICollectionViewDataSource, Delegate, ScrollView)
//  Cells (in Cells/):
//  - PoiImageCell.swift
//  - ProductCardCell.swift
//  - TagCell.swift
//  Views (in Views/):
//  - CustomPageControl.swift
//  - BasicInfoSectionView.swift
//  - ProductsSectionView.swift
//  - KeyDataSectionView.swift
//  - AddressSectionView.swift
//  - FeaturesSectionView.swift
//  - TagsFlowLayout.swift
//

import UIKit
import TRPFoundationKit
import TRPRestKit
import SDWebImage
import MapboxMaps
import MapKit

@objc(SPMTimelinePoiDetailViewController)
public class TimelinePoiDetailViewController: UIViewController {

    // MARK: - Properties
    // Note: Properties are internal for extension access (+CollectionView.swift, +Setup.swift)
    var viewModel: TimelinePoiDetailViewModel!
    var currentImageIndex: Int = 0
    var isDescriptionExpanded: Bool = false

    // Section Views
    var basicInfoSectionView: BasicInfoSectionView!
    var productsSectionView: ProductsSectionView!
    var keyDataSectionView: KeyDataSectionView!
    var addressSectionView: AddressSectionView!
    var featuresSectionView: FeaturesSectionView!

    // Separators
    var separator1: UIView!
    var separator2: UIView!
    var separator3: UIView!
    var separator4: UIView!

    // MARK: - UI Components
    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = true
        scroll.backgroundColor = .white
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return scroll
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0 // We'll control spacing per section
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    // Image Gallery
    lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = ColorSet.neutral100.uiColor
        cv.delegate = self
        cv.dataSource = self
        cv.register(PoiImageCell.self, forCellWithReuseIdentifier: PoiImageCell.reuseIdentifier)
        return cv
    }()

    lazy var pageControl: CustomPageControl = {
        let pc = CustomPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.currentPageIndicatorTintColor = ColorSet.fgPink.uiColor
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.7)
        pc.isUserInteractionEnabled = false
        return pc
    }()

    lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_back", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    // Content Labels
    lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeaker.uiColor
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    lazy var poiNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(22)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    lazy var ratingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    lazy var starImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    lazy var reviewCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        label.numberOfLines = 4 // Show max 4 lines initially
        return label
    }()

    lazy var readMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(readMoreTapped), for: .touchUpInside)

        // Set underlined title
        let title = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.readFullDescription)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSet.montserratRegular.font(16),
            .foregroundColor: ColorSet.fg.uiColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)

        // Add chevron icon
        if let chevronImage = TRPImageController().getImage(inFramework: "ic_chevron_down", inApp: nil)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(chevronImage, for: .normal)
            button.tintColor = ColorSet.fg.uiColor
            button.semanticContentAttribute = .forceRightToLeft // Image on right
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }

        button.isHidden = true
        button.contentHorizontalAlignment = .center
        return button
    }()

    // Activities Section
    lazy var activitiesHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true // Hidden by default, shown only if products exist
        return view
    }()

    lazy var activitiesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.activities)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    lazy var seeMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(seeMoreTapped), for: .touchUpInside)

        // Create attributed title
        let title = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.seeMore)
        let attributedTitle = NSMutableAttributedString(string: title)
        attributedTitle.addAttribute(.font, value: FontSet.montserratRegular.font(14), range: NSRange(location: 0, length: title.count))
        attributedTitle.addAttribute(.foregroundColor, value: ColorSet.fg.uiColor, range: NSRange(location: 0, length: title.count))

        button.setAttributedTitle(attributedTitle, for: .normal)

        // Add chevron icon
        if let chevronImage = TRPImageController().getImage(inFramework: "ic_next", inApp: nil) {
            button.setImage(chevronImage, for: .normal)
            button.tintColor = ColorSet.fg.uiColor
            button.semanticContentAttribute = .forceRightToLeft // Image on right
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        }

        return button
    }()

    lazy var activitiesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = CGSize(width: 280, height: 260)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(ProductCardCell.self, forCellWithReuseIdentifier: ProductCardCell.reuseIdentifier)
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.isHidden = true // Hidden by default
        return cv
    }()

    // Key Data Section
    lazy var keyDataHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.keyData)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    lazy var phoneStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    lazy var phoneIconContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = ColorSet.neutral200.uiColor
        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = TRPImageController().getImage(inFramework: "ic_phone", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = ColorSet.fg.uiColor

        container.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }()

    lazy var phoneValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy var openingHoursStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .fill
        stack.isHidden = true
        return stack
    }()

    lazy var hoursHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    lazy var hoursIconContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = ColorSet.neutral200.uiColor
        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = TRPImageController().getImage(inFramework: "ic_opening_hours", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = ColorSet.fg.uiColor

        container.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }()

    lazy var hoursTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.openingHours)
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    lazy var hoursListStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    // Meeting Point Section
    lazy var meetingPointHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.meetingPoint)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    lazy var mapContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    var mapView: MapView?

    lazy var locationStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.isHidden = true
        return stack
    }()

    lazy var locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_location_point_civi", inApp: nil)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = ColorSet.fgWeaker.uiColor
        return iv
    }()

    lazy var locationContentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

//    private lazy var locationTitleLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.whereItStarts)
//        label.font = FontSet.montserratSemiBold.font(16)
//        label.textColor = ColorSet.fg.uiColor
//        return label
//    }()

    lazy var locationValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.numberOfLines = 0
        return label
    }()

    lazy var viewMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(viewMapTapped), for: .touchUpInside)

        // Create attributed title
        let title = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.viewMap)
        let attributedTitle = NSMutableAttributedString(string: title)
        attributedTitle.addAttribute(.font, value: FontSet.montserratMedium.font(16), range: NSRange(location: 0, length: title.count))
        attributedTitle.addAttribute(.foregroundColor, value: ColorSet.fgTertiary.uiColor, range: NSRange(location: 0, length: title.count))

        button.setAttributedTitle(attributedTitle, for: .normal)

        // Add arrow icon
        if let arrowImage = TRPImageController().getImage(inFramework: "ic_view_map", inApp: nil) {
            button.setImage(arrowImage, for: .normal)
            button.tintColor = ColorSet.fgTertiary.uiColor
            button.semanticContentAttribute = .forceRightToLeft // Image on right
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        }

        button.contentHorizontalAlignment = .trailing
        button.isHidden = true
        return button
    }()

    // Features Section
    lazy var featuresHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.features)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization
    public init(viewModel: TimelinePoiDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        setupUI()
        configureContent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Actions
    @objc private func readMoreTapped() {
        print("[POI Detail] Read More button tapped")

        isDescriptionExpanded.toggle()

        // Toggle description lines
        descriptionLabel.numberOfLines = isDescriptionExpanded ? 0 : 4

        // Update button appearance
        updateReadMoreButtonAppearance()

        // Animate layout change
        UIView.animate(withDuration: 0.3) {
            self.scrollView.layoutIfNeeded()
            self.contentView.layoutIfNeeded()
        }
    }

    private func updateReadMoreButtonAppearance() {
        let title = isDescriptionExpanded
            ? PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.closeFullDescription)
            : PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.readFullDescription)

        // Set underlined title
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSet.montserratRegular.font(16),
            .foregroundColor: ColorSet.fg.uiColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        readMoreButton.setAttributedTitle(attributedTitle, for: .normal)

        // Rotate chevron: 180 degrees when expanded, 0 when collapsed
        let rotation: CGFloat = isDescriptionExpanded ? .pi : 0
        UIView.animate(withDuration: 0.3) {
            self.readMoreButton.imageView?.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }

    @objc private func seeMoreTapped() {
        // TODO: Open activities listing page
        print("See more activities tapped")
    }

    @objc private func viewMapTapped() {
        guard let coordinate = viewModel.getCoordinate() else { return }
        let poiName = viewModel.poi.name

        // Create MKPlacemark with coordinate
        let clCoordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        let placemark = MKPlacemark(coordinate: clCoordinate)

        // Create MKMapItem with placemark
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = poiName

        // Open in Maps with launch options
        // This will show user all available map apps (Apple Maps, Google Maps, Waze, etc.)
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
            MKLaunchOptionsShowsTrafficKey: false
        ] as [String : Any]

        mapItem.openInMaps(launchOptions: launchOptions)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UILabel Extension
private extension UILabel {
    func isTruncated() -> Bool {
        // Check for attributed text first
        if let attributedText = attributedText, attributedText.length > 0 {
            let size = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
            let boundingRect = attributedText.boundingRect(
                with: size,
                options: .usesLineFragmentOrigin,
                context: nil
            )
            return boundingRect.height > bounds.height
        }

        // Fallback to plain text
        guard let text = text, !text.isEmpty else { return false }
        let size = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let boundingRect = text.boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font as Any],
            context: nil
        )
        return boundingRect.height > bounds.height
    }
}
