//
//  NexusCitySelectionVC.swift
//  TRPCoreKit
//
//  Step 1 of the Nexus create-trip flow: search + pick ONE destination city
//  (with a "Top Destinations" row for popular cities), then continue to the
//  date step. Built from scratch (does NOT use the legacy create-trip flow).
//

import UIKit

@objc(SPMNexusCitySelectionVC)
public class NexusCitySelectionVC: TRPBaseUIViewController {

    public var onNext: ((TRPCity) -> Void)?
    public var onBack: (() -> Void)?

    private let viewModel = NexusCitySelectionViewModel()
    private var pillButtons: [UIButton] = []

    // MARK: - UI
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(TRPImageController().getImage(inFramework: "ic_back", inApp: nil), for: .normal)
        b.tintColor = ColorSet.primaryText.uiColor
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratBold.font(16)
        l.textColor = ColorSet.primaryText.uiColor
        l.textAlignment = .center
        l.numberOfLines = 2
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.whereYouGo)
        return l
    }()

    private lazy var nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(NexusLocalizationKeys.localized(NexusLocalizationKeys.next), for: .normal)
        b.titleLabel?.font = FontSet.montserratSemiBold.font(15)
        b.setTitleColor(ColorSet.primary.uiColor, for: .normal)
        b.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        b.isEnabled = false
        b.alpha = 0.4
        return b
    }()

    private lazy var searchBar: TRPSearchBar = {
        let sb = TRPSearchBar()
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.placeholder = NexusLocalizationKeys.localized(NexusLocalizationKeys.search)
        sb.delegate = self
        return sb
    }()

    private lazy var popularLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratBold.font(15)
        l.textColor = ColorSet.primaryText.uiColor
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.popularCities)
        return l
    }()

    private lazy var popularScroll: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.showsHorizontalScrollIndicator = false
        return s
    }()

    private lazy var popularStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.spacing = 8
        return s
    }()

    private lazy var allLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratBold.font(15)
        l.textColor = ColorSet.primaryText.uiColor
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.destinations)
        return l
    }()

    private lazy var tableView: UITableView = {
        let t = UITableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.separatorStyle = .none
        t.delegate = self
        t.dataSource = self
        t.keyboardDismissMode = .onDrag
        t.register(NexusCityRowCell.self, forCellReuseIdentifier: NexusCityRowCell.reuseId)
        return t
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratMedium.font(15)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.textAlignment = .center
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.noResults)
        l.isHidden = true
        return l
    }()

    // Updated to point at the popular section so it can be hidden when empty.
    private var popularTopToSearch: NSLayoutConstraint?
    private var allTopToPopular: NSLayoutConstraint?
    private var allTopToSearch: NSLayoutConstraint?

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(nextButton)
        view.addSubview(searchBar)
        view.addSubview(popularLabel)
        view.addSubview(popularScroll)
        popularScroll.addSubview(popularStack)
        view.addSubview(allLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        let guide = view.safeAreaLayoutGuide
        allTopToPopular = allLabel.topAnchor.constraint(equalTo: popularScroll.bottomAnchor, constant: 16)
        allTopToSearch = allLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -8),

            searchBar.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            popularLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            popularLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            popularScroll.topAnchor.constraint(equalTo: popularLabel.bottomAnchor, constant: 8),
            popularScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            popularScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            popularScroll.heightAnchor.constraint(equalToConstant: 36),

            popularStack.topAnchor.constraint(equalTo: popularScroll.topAnchor),
            popularStack.bottomAnchor.constraint(equalTo: popularScroll.bottomAnchor),
            popularStack.leadingAnchor.constraint(equalTo: popularScroll.leadingAnchor, constant: 16),
            popularStack.trailingAnchor.constraint(equalTo: popularScroll.trailingAnchor, constant: -16),
            popularStack.heightAnchor.constraint(equalTo: popularScroll.heightAnchor),

            allLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: allLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.topAnchor.constraint(equalTo: allLabel.bottomAnchor, constant: 32),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
        allTopToPopular?.isActive = true

        viewModel.delegate = self
        viewModel.loadCities()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Restore selection state if returning from the date step.
        refreshSelectionUI()
    }

    // MARK: - Popular pills
    private func rebuildPopular() {
        pillButtons.forEach { $0.removeFromSuperview() }
        pillButtons.removeAll()
        popularStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let popular = viewModel.popularCities
        let hasPopular = !popular.isEmpty
        popularLabel.isHidden = !hasPopular
        popularScroll.isHidden = !hasPopular
        allTopToPopular?.isActive = hasPopular
        allTopToSearch?.isActive = !hasPopular

        for city in popular {
            let b = UIButton(type: .system)
            b.tag = city.id
            b.setTitle(city.name, for: .normal)
            b.titleLabel?.font = FontSet.montserratMedium.font(13)
            b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            b.layer.cornerRadius = 16
            b.layer.masksToBounds = true
            b.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
            pillButtons.append(b)
            popularStack.addArrangedSubview(b)
        }
        stylePills()
    }

    private func stylePills() {
        for b in pillButtons {
            let selected = viewModel.selectedCity?.id == b.tag
            b.backgroundColor = selected ? ColorSet.primary.uiColor : UIColor(white: 0.95, alpha: 1)
            b.setTitleColor(selected ? .white : ColorSet.primaryText.uiColor, for: .normal)
        }
    }

    private func refreshSelectionUI() {
        stylePills()
        tableView.reloadData()
        let enabled = viewModel.selectedCity != nil
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.4
    }

    // MARK: - Actions
    @objc private func backTapped() { onBack?() }

    @objc private func nextTapped() {
        guard let city = viewModel.selectedCity else { return }
        onNext?(city)
    }

    @objc private func pillTapped(_ sender: UIButton) {
        guard let city = viewModel.popularCities.first(where: { $0.id == sender.tag }) else { return }
        viewModel.select(city)
        refreshSelectionUI()
    }

    // MARK: - ViewModelDelegate
    public override func viewModel(dataLoaded: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.rebuildPopular()
            self.tableView.reloadData()
            let isEmpty = self.viewModel.numberOfCities == 0
            self.emptyLabel.isHidden = !isEmpty
            self.tableView.isHidden = isEmpty
            self.refreshSelectionUI()
        }
    }
}

// MARK: - UITableView
extension NexusCitySelectionVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfCities
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NexusCityRowCell.reuseId, for: indexPath)
        if let cell = cell as? NexusCityRowCell {
            let city = viewModel.city(at: indexPath.row)
            cell.configure(city: city, isSelected: viewModel.isSelected(city))
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.select(viewModel.city(at: indexPath.row))
        view.endEditing(true)
        refreshSelectionUI()
    }
}

// MARK: - TRPSearchBarDelegate
extension NexusCitySelectionVC: TRPSearchBarDelegate {

    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        viewModel.search(text)
    }

    public func searchBarSearchButtonClicked(_ searchBar: TRPSearchBar) {
        view.endEditing(true)
    }
}
