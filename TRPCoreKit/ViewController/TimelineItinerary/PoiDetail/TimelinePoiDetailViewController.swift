//
//  TimelinePoiDetailViewController.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
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
    private var viewModel: TimelinePoiDetailViewModel!
    private var currentImageIndex: Int = 0

    // Section Views
    private var basicInfoSectionView: BasicInfoSectionView!
    private var productsSectionView: ProductsSectionView!
    private var keyDataSectionView: KeyDataSectionView!
    private var addressSectionView: AddressSectionView!
    private var featuresSectionView: FeaturesSectionView!

    // Separators
    private var separator1: UIView!
    private var separator2: UIView!
    private var separator3: UIView!
    private var separator4: UIView!

    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = true
        scroll.backgroundColor = .white
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return scroll
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0 // We'll control spacing per section
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    // Image Gallery
    private lazy var imageCollectionView: UICollectionView = {
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
        cv.register(PoiImageCell.self, forCellWithReuseIdentifier: "PoiImageCell")
        return cv
    }()

    private lazy var pageControl: CustomPageControl = {
        let pc = CustomPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.currentPageIndicatorTintColor = ColorSet.fgPink.uiColor
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.7)
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private lazy var backButton: UIButton = {
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
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeaker.uiColor
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private lazy var poiNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(22)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var ratingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var starImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var reviewCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        label.numberOfLines = 4 // Show max 4 lines initially
        return label
    }()

    private lazy var readMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(readMoreTapped), for: .touchUpInside)

        // Create attributed title with underline
        let title = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.readFullDescription)
        let attributedTitle = NSMutableAttributedString(string: title)
        attributedTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: title.count))
        attributedTitle.addAttribute(.font, value: FontSet.montserratRegular.font(16), range: NSRange(location: 0, length: title.count))
        attributedTitle.addAttribute(.foregroundColor, value: ColorSet.fg.uiColor, range: NSRange(location: 0, length: title.count))

        button.setAttributedTitle(attributedTitle, for: .normal)

        // Add chevron icon
        if let chevronImage = TRPImageController().getImage(inFramework: "ic_next", inApp: nil) {
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
    private lazy var activitiesHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true // Hidden by default, shown only if products exist
        return view
    }()

    private lazy var activitiesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.activities)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var seeMoreButton: UIButton = {
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

    private lazy var activitiesCollectionView: UICollectionView = {
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
        cv.register(ProductCardCell.self, forCellWithReuseIdentifier: "ProductCardCell")
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.isHidden = true // Hidden by default
        return cv
    }()

    // Key Data Section
    private lazy var keyDataHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.keyData)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    private lazy var phoneStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.isHidden = true
        return stack
    }()

    private lazy var phoneIconContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = ColorSet.neutral200.uiColor
        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = TRPImageController().getImage(inFramework: "ic_dialog", inApp: nil)
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

    private lazy var phoneContentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private lazy var phoneTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.phone)
        label.font = FontSet.montserratSemiBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var phoneValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.fgWeaker.uiColor
        label.numberOfLines = 0
        return label
    }()

    private lazy var openingHoursStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.isHidden = true
        return stack
    }()

    private lazy var hoursIconContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = ColorSet.bgGreen.uiColor
        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = TRPImageController().getImage(inFramework: "ic_calendar_check", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = ColorSet.greenAdvantage.uiColor

        container.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }()

    private lazy var hoursContentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private lazy var hoursTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.openingHours)
        label.font = FontSet.montserratSemiBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var hoursValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.fgWeaker.uiColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // Meeting Point Section
    private lazy var meetingPointHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.meetingPoint)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    private lazy var mapContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private var mapView: MapView?

    private lazy var locationStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.isHidden = true
        return stack
    }()

    private lazy var locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_location_point_civi", inApp: nil)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = ColorSet.fgWeaker.uiColor
        return iv
    }()

    private lazy var locationContentStack: UIStackView = {
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

    private lazy var locationValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewMapButton: UIButton = {
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
    private lazy var featuresHeaderLabel: UILabel = {
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

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        // Add ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)

        // Add Image Gallery (outside stack, fixed at top)
        contentView.addSubview(imageCollectionView)
        view.addSubview(pageControl)
        view.addSubview(backButton)

        // Add all sections to stack view
        setupContentStack()

        setupConstraints()
    }

    private func setupContentStack() {
        // Create section views
        basicInfoSectionView = BasicInfoSectionView(
            cityLabel: cityLabel,
            poiNameLabel: poiNameLabel,
            ratingContainerView: ratingContainerView,
            descriptionLabel: descriptionLabel,
            readMoreButton: readMoreButton,
            onReadMoreTapped: { [weak self] in
                self?.readMoreTapped()
            }
        )

        productsSectionView = ProductsSectionView(
            headerView: activitiesHeaderView,
            collectionView: activitiesCollectionView
        )

        keyDataSectionView = KeyDataSectionView(
            headerLabel: keyDataHeaderLabel,
            phoneStack: phoneStackView,
            hoursStack: openingHoursStackView
        )

        addressSectionView = AddressSectionView(
            headerLabel: meetingPointHeaderLabel,
            mapContainer: mapContainerView,
            locationStack: locationStackView,
            viewMapButton: viewMapButton
        )

        featuresSectionView = FeaturesSectionView(
            headerLabel: featuresHeaderLabel,
            tags: viewModel.getFeatures()
        )

        // Create separators
        separator1 = createSeparator()
        separator2 = createSeparator()
        separator3 = createSeparator()
        separator4 = createSeparator()

        // Add sections to stack
        contentStackView.addArrangedSubview(basicInfoSectionView)
        contentStackView.addArrangedSubview(separator1)
        contentStackView.addArrangedSubview(productsSectionView)
        contentStackView.addArrangedSubview(separator2)
        contentStackView.addArrangedSubview(keyDataSectionView)
        contentStackView.addArrangedSubview(separator3)
        contentStackView.addArrangedSubview(addressSectionView)
        contentStackView.addArrangedSubview(separator4)
        contentStackView.addArrangedSubview(featuresSectionView)

        // Setup subcomponents
        setupRatingContainer()
        setupActivitiesHeader()
        setupPhoneStack()
        setupHoursStack()
        setupLocationStack()
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = ColorSet.neutral200.uiColor
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func setupRatingContainer() {
        ratingContainerView.addSubview(ratingLabel)
        ratingContainerView.addSubview(starImageView)
        ratingContainerView.addSubview(reviewCountLabel)

        NSLayoutConstraint.activate([
            ratingLabel.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 4),
            starImageView.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),
            reviewCountLabel.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 8),
            reviewCountLabel.trailingAnchor.constraint(equalTo: ratingContainerView.trailingAnchor),
            reviewCountLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor)
        ])
    }

    private func setupActivitiesHeader() {
        activitiesHeaderView.addSubview(activitiesLabel)
        activitiesHeaderView.addSubview(seeMoreButton)

        NSLayoutConstraint.activate([
            activitiesLabel.leadingAnchor.constraint(equalTo: activitiesHeaderView.leadingAnchor),
            activitiesLabel.centerYAnchor.constraint(equalTo: activitiesHeaderView.centerYAnchor),
            seeMoreButton.trailingAnchor.constraint(equalTo: activitiesHeaderView.trailingAnchor),
            seeMoreButton.centerYAnchor.constraint(equalTo: activitiesHeaderView.centerYAnchor),
            activitiesHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupPhoneStack() {
        phoneStackView.addArrangedSubview(phoneIconContainerView)
        phoneStackView.addArrangedSubview(phoneContentStack)
        phoneContentStack.addArrangedSubview(phoneTitleLabel)
        phoneContentStack.addArrangedSubview(phoneValueLabel)

        NSLayoutConstraint.activate([
            phoneIconContainerView.widthAnchor.constraint(equalToConstant: 40),
            phoneIconContainerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupHoursStack() {
        openingHoursStackView.addArrangedSubview(hoursIconContainerView)
        openingHoursStackView.addArrangedSubview(hoursContentStack)
        hoursContentStack.addArrangedSubview(hoursTitleLabel)
        hoursContentStack.addArrangedSubview(hoursValueLabel)

        NSLayoutConstraint.activate([
            hoursIconContainerView.widthAnchor.constraint(equalToConstant: 40),
            hoursIconContainerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupLocationStack() {
        locationStackView.addArrangedSubview(locationIconView)
        locationStackView.addArrangedSubview(locationContentStack)
        locationContentStack.addArrangedSubview(locationValueLabel)

        NSLayoutConstraint.activate([
            locationIconView.widthAnchor.constraint(equalToConstant: 24),
            locationIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func setupConstraints() {
        let screenWidth = UIScreen.main.bounds.width
        let imageHeight = screenWidth // 1:1 ratio

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Image Gallery (1:1 ratio, fixed at top)
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalToConstant: imageHeight),

            // Page Control
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Content Stack (below image gallery)
            contentStackView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func configureContent() {
        let poi = viewModel.poi

        // Configure Images
        let images = viewModel.getImageUrls()
        pageControl.numberOfPages = max(images.count, 1)
        pageControl.currentPage = 0
        pageControl.isHidden = images.count <= 1
        imageCollectionView.reloadData()

        // Configure Labels
        let cityName = viewModel.getCityName()
        cityLabel.text = cityName.isEmpty ? "Unknown Location" : cityName
        cityLabel.isHidden = cityName.isEmpty

        poiNameLabel.text = poi.name

        // Configure Rating
        if let rating = poi.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)

            // Create underlined attributed string for review count
            let reviewCount = poi.ratingCount ?? 0
            let reviewText = "\(reviewCount) opiniones"
            let attributedString = NSMutableAttributedString(string: reviewText)
            attributedString.addAttribute(.underlineStyle,
                                         value: NSUnderlineStyle.single.rawValue,
                                         range: NSRange(location: 0, length: reviewText.count))
            reviewCountLabel.attributedText = attributedString

            ratingContainerView.isHidden = false
        } else {
            ratingContainerView.isHidden = true
        }

        // Configure Description
        if let description = poi.description, !description.isEmpty {
            // Create attributed string with line height
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8 // 24 line height - 16 font size = 8
            paragraphStyle.alignment = .center

            let attributedString = NSMutableAttributedString(string: description)
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: description.count))
            attributedString.addAttribute(.font, value: FontSet.montserratMedium.font(16), range: NSRange(location: 0, length: description.count))
            attributedString.addAttribute(.foregroundColor, value: ColorSet.fg.uiColor, range: NSRange(location: 0, length: description.count))

            descriptionLabel.attributedText = attributedString
            descriptionLabel.isHidden = false

            // Force full layout before checking truncation
            view.setNeedsLayout()
            view.layoutIfNeeded()

            // Check if description needs "Read More" button
            let isTruncated = descriptionLabel.isTruncated()
            readMoreButton.isHidden = !isTruncated

            print("[POI Detail] Description truncated: \(isTruncated)")
        } else {
            descriptionLabel.isHidden = true
            readMoreButton.isHidden = true
        }

        // Configure Products Section
        let hasProducts = viewModel.hasProducts()
        productsSectionView.isHidden = !hasProducts

        if hasProducts {
            activitiesHeaderView.isHidden = false
            activitiesCollectionView.isHidden = false
            activitiesCollectionView.reloadData()
        }

        // Configure Key Data Section
        let hasKeyData = viewModel.hasKeyData()
        keyDataSectionView.isHidden = !hasKeyData

        if hasKeyData {
            keyDataHeaderLabel.isHidden = false

            let hasPhone = viewModel.getPhone() != nil
            let hasHours = viewModel.getFormattedOpeningHours() != nil

            phoneStackView.isHidden = !hasPhone
            openingHoursStackView.isHidden = !hasHours

            if hasPhone {
                phoneValueLabel.text = viewModel.getPhone()
            }

            if hasHours, let hoursText = viewModel.getFormattedOpeningHours() {
                // Create attributed string with line spacing
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4

                let attributedString = NSMutableAttributedString(string: hoursText)
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: hoursText.count))
                attributedString.addAttribute(.font, value: FontSet.montserratRegular.font(14), range: NSRange(location: 0, length: hoursText.count))
                attributedString.addAttribute(.foregroundColor, value: ColorSet.fgWeaker.uiColor, range: NSRange(location: 0, length: hoursText.count))

                hoursValueLabel.attributedText = attributedString
            }
        }

        // Configure Address Section
        let hasMeetingPoint = viewModel.hasMeetingPoint()
        addressSectionView.isHidden = !hasMeetingPoint

        if hasMeetingPoint {
            meetingPointHeaderLabel.isHidden = false
            mapContainerView.isHidden = false
            locationStackView.isHidden = false
            viewMapButton.isHidden = false

            // Setup MapView
            setupMapView()

            // Set address
            if let address = viewModel.getAddress() {
                locationValueLabel.text = address
            }
        }

        // Configure Features Section
        let hasFeatures = viewModel.hasFeatures()
        featuresSectionView.isHidden = !hasFeatures

        if hasFeatures {
            featuresHeaderLabel.isHidden = false
            featuresSectionView.updateTags(viewModel.getFeatures())
        }

        // Control separator visibility
        // separator1: before products section
        separator1.isHidden = productsSectionView.isHidden

        // separator2: before key data section
        separator2.isHidden = keyDataSectionView.isHidden

        // separator3: before address section
        separator3.isHidden = addressSectionView.isHidden

        // separator4: before features section
        separator4.isHidden = featuresSectionView.isHidden

        // Note: UIStackView automatically handles layout when arrangedSubviews are hidden
    }

    private func setupMapView() {
        // Remove existing map if any
        mapView?.removeFromSuperview()
        
        guard let coordinate = viewModel.getCoordinate() else { return }
        let center = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        let camera = CameraOptions(center: center, zoom: 15)
        let options = MapInitOptions(cameraOptions: camera)
        let newMapView = MapView(frame: .zero, mapInitOptions: options)

        // Create point annotation with ic_civi_point
        var pointAnnotation = PointAnnotation(coordinate: center)
        if let civiPointImage = TRPImageController().getImage(inFramework: "ic_civi_point", inApp: nil) {
            pointAnnotation.image = .init(image: civiPointImage, name: "ic_civi_point")
        }

        // Create annotation manager
        let pointAnnotationManager = newMapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.annotations = [pointAnnotation]

        newMapView.gestures.options.pinchZoomEnabled = true
        newMapView.gestures.options.quickZoomEnabled = true
        newMapView.translatesAutoresizingMaskIntoConstraints = false

        mapContainerView.addSubview(newMapView)
        NSLayoutConstraint.activate([
            newMapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            newMapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor),
            newMapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            newMapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor)
        ])

        newMapView.layer.cornerRadius = 12
        newMapView.clipsToBounds = true

        mapView = newMapView
    }

    // MARK: - Actions
    @objc private func readMoreTapped() {
        print("[POI Detail] Read More button tapped")

        // Expand description
        descriptionLabel.numberOfLines = 0
        readMoreButton.isHidden = true

        // Animate layout change
        UIView.animate(withDuration: 0.3) {
            self.scrollView.layoutIfNeeded()
            self.contentView.layoutIfNeeded()
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

// MARK: - UICollectionViewDataSource
extension TimelinePoiDetailViewController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == imageCollectionView {
            return viewModel.getImageUrls().count
        } else if collectionView == activitiesCollectionView {
            return viewModel.getProducts().count
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PoiImageCell", for: indexPath) as? PoiImageCell else {
                return UICollectionViewCell()
            }

            let imageUrl = viewModel.getImageUrls()[indexPath.item]
            cell.configure(with: imageUrl)

            return cell
        } else if collectionView == activitiesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCardCell", for: indexPath) as? ProductCardCell else {
                return UICollectionViewCell()
            }

            let product = viewModel.getProducts()[indexPath.item]
            cell.configure(with: product)

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TimelinePoiDetailViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imageCollectionView {
            let width = collectionView.bounds.width
            return CGSize(width: width, height: width) // 1:1 ratio
        } else if collectionView == activitiesCollectionView {
            let width: CGFloat = 280
            let height: CGFloat = 280 // Increased for dynamic content
            return CGSize(width: width, height: height)
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == activitiesCollectionView {
            let product = viewModel.getProducts()[indexPath.item]
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: product.id)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension TimelinePoiDetailViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imageCollectionView else { return }

        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)

        if currentPage != currentImageIndex {
            currentImageIndex = currentPage
            pageControl.currentPage = currentPage
        }
    }
}

// MARK: - PoiImageCell
private class PoiImageCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = ColorSet.neutral100.uiColor
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with urlString: String) {
        if urlString.isEmpty {
            // Show placeholder for empty URL
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        } else if let url = URL(string: urlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, error, _, _ in
                if error != nil || image == nil {
                    self?.imageView.backgroundColor = ColorSet.neutral200.uiColor
                }
            }
        }
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

// MARK: - CustomPageControl
private class CustomPageControl: UIView {

    var numberOfPages: Int = 0 {
        didSet {
            setupIndicators()
        }
    }

    var currentPage: Int = 0 {
        didSet {
            updateIndicators()
        }
    }

    var currentPageIndicatorTintColor: UIColor = .white
    var pageIndicatorTintColor: UIColor = UIColor.white

    private var indicators: [UIView] = []
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupIndicators() {
        // Remove old indicators
        indicators.forEach { $0.removeFromSuperview() }
        indicators.removeAll()

        // Create new indicators
        for index in 0..<numberOfPages {
            let indicator = UIView()
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.layer.cornerRadius = 5
            indicator.clipsToBounds = true

            // Set initial size (small dot)
            NSLayoutConstraint.activate([
                indicator.widthAnchor.constraint(equalToConstant: 8),
                indicator.heightAnchor.constraint(equalToConstant: 8)
            ])

            indicator.backgroundColor = index == currentPage ? currentPageIndicatorTintColor : pageIndicatorTintColor

            stackView.addArrangedSubview(indicator)
            indicators.append(indicator)
        }

        updateIndicators()
    }

    private func updateIndicators() {
        for (index, indicator) in indicators.enumerated() {
            let isSelected = index == currentPage

            // Remove old constraints
            indicator.constraints.forEach { constraint in
                if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                    constraint.isActive = false
                }
            }

            UIView.animate(withDuration: 0.3) {
                if isSelected {
                    // Pill shape (wide)
                    indicator.backgroundColor = self.currentPageIndicatorTintColor
                    NSLayoutConstraint.activate([
                        indicator.widthAnchor.constraint(equalToConstant: 14),
                        indicator.heightAnchor.constraint(equalToConstant: 8)
                    ])
                } else {
                    // Small dot
                    indicator.backgroundColor = self.pageIndicatorTintColor
                    NSLayoutConstraint.activate([
                        indicator.widthAnchor.constraint(equalToConstant: 8),
                        indicator.heightAnchor.constraint(equalToConstant: 8)
                    ])
                }

                self.layoutIfNeeded()
            }
        }
    }
}

// MARK: - ProductCardCell
private class ProductCardCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = ColorSet.neutral100.uiColor
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    private let ratingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let freeCancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(12)
        label.textColor = ColorSet.greenAdvantage.uiColor
        label.text = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.freeCancellation)
        return label
    }()

    private lazy var detailsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .white

        // Add rating subviews
        ratingContainerView.addSubview(ratingLabel)
        ratingContainerView.addSubview(starImageView)

        // Add to details stack
        detailsStackView.addArrangedSubview(ratingContainerView)
        detailsStackView.addArrangedSubview(durationLabel)
        detailsStackView.addArrangedSubview(freeCancellationLabel)

        // Add to content view
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailsStackView)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            // Cell width
            contentView.widthAnchor.constraint(equalToConstant: 280),

            // Image
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 152),

            // Title
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Details Stack (rating, duration, free cancellation)
            detailsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),

            // Rating Container
            ratingContainerView.heightAnchor.constraint(equalToConstant: 18),

            // Rating Label - Star sıralaması: RatingLabel - Star
            ratingLabel.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),

            // Star Image
            starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 4),
            starImageView.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: ratingContainerView.trailingAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            // Price - Sağ alt köşe
            priceLabel.topAnchor.constraint(greaterThanOrEqualTo: detailsStackView.bottomAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8)
        ])
    }

    func configure(with product: TRPBookingProduct) {
        titleLabel.text = product.title

        // Configure Image
        if let imageUrlString = product.image, !imageUrlString.isEmpty, let url = URL(string: imageUrlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, error, _, _ in
                if error != nil || image == nil {
                    self?.imageView.backgroundColor = ColorSet.neutral200.uiColor
                }
            }
        } else {
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        }

        // Configure Rating
        if let rating = product.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            ratingContainerView.isHidden = false
        } else {
            ratingContainerView.isHidden = true
        }

        // Configure Duration
        if let duration = product.duration, !duration.isEmpty {
            durationLabel.text = duration
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }

        // Configure Free Cancellation
        let hasNonRefundable = product.info.contains { $0.lowercased() == "non_refundable" }
        freeCancellationLabel.isHidden = hasNonRefundable

        // Configure Price with "From:" prefix
        let fromText = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.from)

        if let price = product.price, let currency = product.currency {
            let priceText = "\(currency) \(String(format: "%.2f", price))"
            let fullText = "\(fromText) \(priceText)"

            let attributedString = NSMutableAttributedString(string: fullText)

            // "From:" -> Medium 14, fg
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratMedium.font(14),
                                        range: NSRange(location: 0, length: fromText.count))
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: NSRange(location: 0, length: fromText.count))

            // Price (with space) -> Bold 16, fg
            let priceRange = NSRange(location: fromText.count, length: fullText.count - fromText.count)
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratBold.font(16),
                                        range: priceRange)
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: priceRange)

            priceLabel.attributedText = attributedString
        } else if let priceDescription = product.priceDescription {
            let fullText = "\(fromText) \(priceDescription)"

            let attributedString = NSMutableAttributedString(string: fullText)

            // "From:" -> Medium 14, fg
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratMedium.font(14),
                                        range: NSRange(location: 0, length: fromText.count))
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: NSRange(location: 0, length: fromText.count))

            // Price (with space) -> Bold 16, fg
            let priceRange = NSRange(location: fromText.count, length: fullText.count - fromText.count)
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratBold.font(16),
                                        range: priceRange)
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: priceRange)

            priceLabel.attributedText = attributedString
        } else {
            priceLabel.text = ""
        }
    }
}

// MARK: - Custom Section Views

// MARK: - BasicInfoSectionView
private class BasicInfoSectionView: UIView {

    private let cityLabel: UILabel
    private let poiNameLabel: UILabel
    private let ratingContainerView: UIView
    private let descriptionLabel: UILabel
    private let readMoreButton: UIButton
    private let onReadMoreTapped: () -> Void

    private let descriptionStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    init(cityLabel: UILabel, poiNameLabel: UILabel, ratingContainerView: UIView, descriptionLabel: UILabel, readMoreButton: UIButton, onReadMoreTapped: @escaping () -> Void) {
        self.cityLabel = cityLabel
        self.poiNameLabel = poiNameLabel
        self.ratingContainerView = ratingContainerView
        self.descriptionLabel = descriptionLabel
        self.readMoreButton = readMoreButton
        self.onReadMoreTapped = onReadMoreTapped

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(cityLabel)
        addSubview(poiNameLabel)
        addSubview(ratingContainerView)
        addSubview(descriptionStackView)

        // Add description and button to stack (button will auto-hide when isHidden = true)
        descriptionStackView.addArrangedSubview(descriptionLabel)
        descriptionStackView.addArrangedSubview(readMoreButton)

        NSLayoutConstraint.activate([
            // City Label
            cityLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            cityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cityLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // POI Name
            poiNameLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 16),
            poiNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            poiNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Rating Container
            ratingContainerView.topAnchor.constraint(equalTo: poiNameLabel.bottomAnchor, constant: 12),
            ratingContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ratingContainerView.heightAnchor.constraint(equalToConstant: 24),

            // Description Stack (automatically handles hidden readMoreButton)
            descriptionStackView.topAnchor.constraint(equalTo: ratingContainerView.bottomAnchor, constant: 20),
            descriptionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            descriptionStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            descriptionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),

            // Ensure description label takes full width within stack
            descriptionLabel.widthAnchor.constraint(equalTo: descriptionStackView.widthAnchor)
        ])
    }
}

// MARK: - ProductsSectionView
private class ProductsSectionView: UIView {

    private let headerView: UIView
    private let collectionView: UICollectionView
    private var collectionHeightConstraint: NSLayoutConstraint!

    init(headerView: UIView, collectionView: UICollectionView) {
        self.headerView = headerView
        self.collectionView = collectionView

        super.init(frame: .zero)
        setupView()
        observeCollectionViewContentSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerView)
        addSubview(collectionView)

        // Create dynamic height constraint
        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 280)

        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // CollectionView
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionHeightConstraint,
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func observeCollectionViewContentSize() {
        collectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let newSize = change?[.newKey] as? CGSize {
                collectionHeightConstraint.constant = newSize.height
            }
        }
    }

    deinit {
        collectionView.removeObserver(self, forKeyPath: "contentSize")
    }
}

// MARK: - KeyDataSectionView
private class KeyDataSectionView: UIView {

    private let headerLabel: UILabel
    private let phoneStack: UIStackView
    private let hoursStack: UIStackView
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    init(headerLabel: UILabel, phoneStack: UIStackView, hoursStack: UIStackView) {
        self.headerLabel = headerLabel
        self.phoneStack = phoneStack
        self.hoursStack = hoursStack

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerLabel)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(phoneStack)
        contentStackView.addArrangedSubview(hoursStack)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Content Stack (automatically handles hidden subviews)
            contentStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }
}

// MARK: - AddressSectionView
private class AddressSectionView: UIView {

    private let headerLabel: UILabel
    private let mapContainer: UIView
    private let locationStack: UIStackView
    private let viewMapButton: UIButton
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()

    init(headerLabel: UILabel, mapContainer: UIView, locationStack: UIStackView, viewMapButton: UIButton) {
        self.headerLabel = headerLabel
        self.mapContainer = mapContainer
        self.locationStack = locationStack
        self.viewMapButton = viewMapButton

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerLabel)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(mapContainer)
        contentStackView.addArrangedSubview(locationStack)
        contentStackView.addArrangedSubview(viewMapButton)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Content Stack (automatically handles hidden subviews)
            contentStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),

            // Map Container height (when visible)
            mapContainer.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
}

// MARK: - FeaturesSectionView
private class FeaturesSectionView: UIView {

    private let headerLabel: UILabel
    private let tagsCollectionView: UICollectionView
    private var tags: [String] = []
    private var collectionHeightConstraint: NSLayoutConstraint!

    init(headerLabel: UILabel, tags: [String]) {
        self.headerLabel = headerLabel
        self.tags = tags

        let layout = TagsFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16

        self.tagsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        tagsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tagsCollectionView.backgroundColor = .clear
        tagsCollectionView.isScrollEnabled = false
        tagsCollectionView.dataSource = self
        tagsCollectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")

        addSubview(headerLabel)
        addSubview(tagsCollectionView)

        // Create height constraint for collection view
        collectionHeightConstraint = tagsCollectionView.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Tags CollectionView
            tagsCollectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            tagsCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tagsCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tagsCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            collectionHeightConstraint
        ])
    }

    func updateTags(_ newTags: [String]) {
        tags = newTags
        tagsCollectionView.reloadData()

        // Force layout and update height after reload
        tagsCollectionView.layoutIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let contentHeight = self.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
            self.collectionHeightConstraint.constant = contentHeight
            self.layoutIfNeeded()
        }
    }
}

// MARK: - FeaturesSectionView CollectionView DataSource
extension FeaturesSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        cell.configure(with: tags[indexPath.item])
        return cell
    }
}

// MARK: - TagCell
private class TagCell: UICollectionViewCell {

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgGray.uiColor
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = ColorSet.neutral200.uiColor
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }

    func configure(with tag: String) {
        label.text = tag
    }
}

// MARK: - TagsFlowLayout
private class TagsFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        for layoutAttribute in attributes {
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }

        return attributes
    }
}
