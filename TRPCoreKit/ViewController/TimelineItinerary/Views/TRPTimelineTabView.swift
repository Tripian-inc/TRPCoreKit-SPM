//
//  TRPTimelineTabView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

public struct TRPTimelineTabItem {
    let id: String
    let title: String
    
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

protocol TRPTimelineTabViewDelegate: AnyObject {
    func timelineTabView(_ view: TRPTimelineTabView, didSelectTabAtIndex index: Int, tabId: String)
}

class TRPTimelineTabView: UIView {
    
    // MARK: - Properties
    weak var delegate: TRPTimelineTabViewDelegate?
    private var selectedIndex: Int = 0
    private var tabItems: [TRPTimelineTabItem] = []
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        return stack
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.borderActive.uiColor
        return view
    }()
    
    private let underlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.primary.uiColor
        return view
    }()
    
    private var underlineLeadingConstraint: NSLayoutConstraint?
    private var underlineWidthConstraint: NSLayoutConstraint?
    private var tabButtons: [UIButton] = []
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .white
        
        addSubview(stackView)
        addSubview(separatorLine)
        addSubview(underlineView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: leadingAnchor)
        underlineLeadingConstraint?.isActive = true
    }
    
    private func createTabButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = FontSet.montserratRegular.font(14)
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex, index < tabItems.count else { return }
        
        selectedIndex = index
        updateTabAppearance()
        animateUnderline(to: index)
        delegate?.timelineTabView(self, didSelectTabAtIndex: index, tabId: tabItems[index].id)
    }
    
    // MARK: - Updates
    private func updateTabAppearance() {
        for (index, button) in tabButtons.enumerated() {
            if index == selectedIndex {
                button.setTitleColor(ColorSet.primary.uiColor, for: .normal)
                button.titleLabel?.font = FontSet.montserratSemiBold.font(14)
            } else {
                button.setTitleColor(ColorSet.fg.uiColor, for: .normal)
                button.titleLabel?.font = FontSet.montserratRegular.font(14)
            }
        }
    }
    
    private func animateUnderline(to index: Int) {
        guard tabItems.count > 0 else { return }
        
        let tabWidth = bounds.width / CGFloat(tabItems.count)
        let targetLeading = tabWidth * CGFloat(index)
        
        underlineLeadingConstraint?.constant = targetLeading
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    public func configure(with tabs: [TRPTimelineTabItem], selectedIndex: Int = 0) {
        // Clear existing tabs
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Store new tabs
        self.tabItems = tabs
        self.selectedIndex = min(selectedIndex, tabs.count - 1)
        
        // Create buttons for each tab
        for (index, tab) in tabs.enumerated() {
            let button = createTabButton(title: tab.title, index: index)
            stackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // Update underline width constraint
        underlineWidthConstraint?.isActive = false
        if tabs.count > 0 {
            underlineWidthConstraint = underlineView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1.0/CGFloat(tabs.count))
            underlineWidthConstraint?.isActive = true
        }
        
        // Update appearance
        updateTabAppearance()
        layoutIfNeeded()
        
        // Position underline
        if tabs.count > 0 {
            let tabWidth = bounds.width / CGFloat(tabs.count)
            underlineLeadingConstraint?.constant = tabWidth * CGFloat(self.selectedIndex)
        }
    }
    
    public func selectTab(at index: Int, animated: Bool = false) {
        guard index != selectedIndex, index >= 0, index < tabItems.count else { return }
        
        selectedIndex = index
        updateTabAppearance()
        
        if animated {
            animateUnderline(to: index)
        } else {
            let tabWidth = bounds.width / CGFloat(tabItems.count)
            underlineLeadingConstraint?.constant = tabWidth * CGFloat(index)
            layoutIfNeeded()
        }
    }
    
    public func selectTab(byId id: String, animated: Bool = false) {
        guard let index = tabItems.firstIndex(where: { $0.id == id }) else { return }
        selectTab(at: index, animated: animated)
    }
    
    public func getSelectedIndex() -> Int {
        return selectedIndex
    }
    
    public func getSelectedTabId() -> String? {
        guard selectedIndex < tabItems.count else { return nil }
        return tabItems[selectedIndex].id
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update underline position when layout changes
        guard tabItems.count > 0 else { return }
        let tabWidth = bounds.width / CGFloat(tabItems.count)
        underlineLeadingConstraint?.constant = tabWidth * CGFloat(selectedIndex)
    }
}

