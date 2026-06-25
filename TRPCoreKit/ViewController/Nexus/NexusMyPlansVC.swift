//
//  NexusMyPlansVC.swift
//  TRPCoreKit
//
//  Nexus "My Plans" — lists the user's existing not-past timelines when the SDK
//  opens with no reservations. A bottom-right FAB starts the create-trip flow;
//  tapping a card opens that timeline; the header back button closes the SDK.
//  Built from scratch (does NOT use the legacy MyTripVC).
//

import UIKit

@objc(SPMNexusMyPlansVC)
public class NexusMyPlansVC: TRPBaseUIViewController {

    // Wired by the coordinator.
    public var onAddTrip: (() -> Void)?
    public var onSelectTrip: ((TRPTimeline) -> Void)?
    public var onClose: (() -> Void)?

    private let viewModel = NexusMyPlansViewModel()

    // MARK: - UI
    private lazy var headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

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
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.myPlans)
        return l
    }()

    private lazy var tableView: UITableView = {
        let t = UITableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.separatorStyle = .none
        t.backgroundColor = .clear
        t.delegate = self
        t.dataSource = self
        t.rowHeight = UITableView.automaticDimension
        t.estimatedRowHeight = 250
        t.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 96, right: 0)
        t.register(NexusTripCardCell.self, forCellReuseIdentifier: NexusTripCardCell.reuseId)
        return t
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratMedium.font(15)
        l.textColor = ColorSet.primaryText.uiColor
        l.textAlignment = .center
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.noTripsYet)
        l.isHidden = true
        return l
    }()

    private lazy var fabButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = ColorSet.primary.uiColor
        b.tintColor = .white
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.layer.cornerRadius = 28
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.2
        b.layer.shadowOffset = CGSize(width: 0, height: 2)
        b.layer.shadowRadius = 4
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(fabButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56),
        ])

        viewModel.delegate = self
        viewModel.loadTrips()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Refresh so a trip just created via the FAB appears on return.
        viewModel.loadTrips()
    }

    // MARK: - Actions
    @objc private func backTapped() { onClose?() }
    @objc private func addTapped() { onAddTrip?() }

    // MARK: - ViewModelDelegate
    public override func viewModel(dataLoaded: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            let isEmpty = self.viewModel.numberOfTrips == 0
            self.emptyLabel.isHidden = !isEmpty
            self.tableView.isHidden = isEmpty
        }
    }
}

// MARK: - UITableView
extension NexusMyPlansVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfTrips
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NexusTripCardCell.reuseId, for: indexPath)
        if let cell = cell as? NexusTripCardCell {
            cell.configure(with: viewModel.trip(at: indexPath.row))
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectTrip?(viewModel.trip(at: indexPath.row))
    }
}
