//
//  TRPTimeRangeSelectionViewController.swift
//  TRPCoreKit
//
//  Created on 2.12.2025.
//
//  USAGE EXAMPLE:
//  
//  class YourViewController: UIViewController, TRPTimeRangeSelectionDelegate {
//      
//      func showTimeRangeSelection() {
//          let timeRangeVC = TRPTimeRangeSelectionViewController()
//          timeRangeVC.delegate = self
//          
//          // Option 1: Set with String format
//          timeRangeVC.setInitialTimes(from: "11:00 AM", to: "12:00 PM")
//          
//          // Option 2: Set with Date objects
//          // let fromDate = Date()
//          // let toDate = Date().addingTimeInterval(3600)
//          // timeRangeVC.setInitialTimes(from: fromDate, to: toDate)
//          
//          timeRangeVC.show(from: self) // Presents as pageSheet modal
//      }
//      
//      // MARK: - TRPTimeRangeSelectionDelegate
//      func timeRangeSelected(fromTime: String, toTime: String) {
//          print("Selected time range (String): \(fromTime) - \(toTime)")
//      }
//      
//      func timeRangeSelected(fromDate: Date, toDate: Date) {
//          print("Selected time range (Date): \(fromDate) - \(toDate)")
//          // Use Date objects for API calls or date calculations
//      }
//  }
//

import UIKit

protocol TRPTimeRangeSelectionDelegate: AnyObject {
    func timeRangeSelected(fromTime: String, toTime: String)
    func timeRangeSelected(fromDate: Date, toDate: Date)
}

class TRPTimeRangeSelectionViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TRPTimeRangeSelectionDelegate?
    private var fromTime: String = "11:00 AM"
    private var toTime: String = "12:00 PM"
    private var fromDate: Date?
    private var toDate: Date?
    
    private let contentView = UIView()
    
    // Track which field is being edited
    private enum EditingField {
        case from
        case until
    }
    private var currentEditingField: EditingField = .until
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hora"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.textColor = TRPColor.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = TRPColor.darkGrey
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let fromLabel: UILabel = {
        let label = UILabel()
        label.text = "From"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = TRPColor.darkGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fromTextField: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.borderActive.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fromTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = TRPColor.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fromClockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock")
        imageView.tintColor = TRPColor.darkGrey
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let toLabel: UILabel = {
        let label = UILabel()
        label.text = "Until"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = TRPColor.darkGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let toTextField: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.borderActive.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let toTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = TRPColor.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let toClockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock")
        imageView.tintColor = TRPColor.darkGrey
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "en_US") // Force 12-hour format with AM/PM
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Confirmar", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ColorSet.primary.uiColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPickerView()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add content view
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        
        // Add UI components to content view
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(fromLabel)
        contentView.addSubview(fromTextField)
        contentView.addSubview(toLabel)
        contentView.addSubview(toTextField)
        contentView.addSubview(timePicker)
        contentView.addSubview(confirmButton)
        
        // Add icons and labels to text fields
        fromTextField.addSubview(fromClockIcon)
        fromTextField.addSubview(fromTimeLabel)
        toTextField.addSubview(toClockIcon)
        toTextField.addSubview(toTimeLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Close button
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // From label
            fromLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            fromLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // From text field
            fromTextField.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 8),
            fromTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fromTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            fromTextField.heightAnchor.constraint(equalToConstant: 48),
            
            // From clock icon
            fromClockIcon.leadingAnchor.constraint(equalTo: fromTextField.leadingAnchor, constant: 12),
            fromClockIcon.centerYAnchor.constraint(equalTo: fromTextField.centerYAnchor),
            fromClockIcon.widthAnchor.constraint(equalToConstant: 20),
            fromClockIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // From time label
            fromTimeLabel.leadingAnchor.constraint(equalTo: fromClockIcon.trailingAnchor, constant: 8),
            fromTimeLabel.centerYAnchor.constraint(equalTo: fromTextField.centerYAnchor),
            
            // To label
            toLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            toLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // To text field
            toTextField.topAnchor.constraint(equalTo: toLabel.bottomAnchor, constant: 8),
            toTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            toTextField.heightAnchor.constraint(equalToConstant: 48),
            
            // To clock icon
            toClockIcon.leadingAnchor.constraint(equalTo: toTextField.leadingAnchor, constant: 12),
            toClockIcon.centerYAnchor.constraint(equalTo: toTextField.centerYAnchor),
            toClockIcon.widthAnchor.constraint(equalToConstant: 20),
            toClockIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // To time label
            toTimeLabel.leadingAnchor.constraint(equalTo: toClockIcon.trailingAnchor, constant: 8),
            toTimeLabel.centerYAnchor.constraint(equalTo: toTextField.centerYAnchor),
            
            // Time picker
            timePicker.topAnchor.constraint(equalTo: fromTextField.bottomAnchor, constant: 24),
            timePicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 200),
            
            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        let fromTapGesture = UITapGestureRecognizer(target: self, action: #selector(fromFieldTapped))
        fromTextField.addGestureRecognizer(fromTapGesture)
        
        let toTapGesture = UITapGestureRecognizer(target: self, action: #selector(toFieldTapped))
        toTextField.addGestureRecognizer(toTapGesture)
    }
    
    private func setupPickerView() {
        // Add value changed listener
        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)
        
        // Set initial date from toTime
        if let date = dateFromTimeString(toTime) {
            timePicker.date = date
        }
        
        // Highlight the initial editing field
        highlightTextField(toTextField, highlight: true)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func confirmButtonTapped() {
        // Send formatted strings
        delegate?.timeRangeSelected(fromTime: fromTime, toTime: toTime)
        
        // Send Date objects if available
        if let fromDate = fromDate, let toDate = toDate {
            delegate?.timeRangeSelected(fromDate: fromDate, toDate: toDate)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func fromFieldTapped() {
        currentEditingField = .from
        highlightTextField(fromTextField, highlight: true)
        highlightTextField(toTextField, highlight: false)
        updatePickerForCurrentField()
    }
    
    @objc private func toFieldTapped() {
        currentEditingField = .until
        highlightTextField(fromTextField, highlight: false)
        highlightTextField(toTextField, highlight: true)
        updatePickerForCurrentField()
    }
    
    @objc private func timePickerValueChanged() {
        let selectedDate = timePicker.date
        let timeString = timeStringFromDate(selectedDate)
        
        // Update the appropriate field based on which one is being edited
        switch currentEditingField {
        case .from:
            fromTime = timeString
            fromDate = selectedDate
            fromTimeLabel.text = timeString
        case .until:
            toTime = timeString
            toDate = selectedDate
            toTimeLabel.text = timeString
        }
    }
    
    private func highlightTextField(_ textField: UIView, highlight: Bool) {
        UIView.animate(withDuration: 0.2) {
            textField.backgroundColor = .clear
            textField.layer.borderWidth = highlight ? 1.5 : 1
            textField.layer.borderColor = highlight ? ColorSet.borderActive.uiColor.cgColor : ColorSet.bgDisabled.uiColor.cgColor
        }
    }
    
    // MARK: - Public Methods
    func show(from parentViewController: UIViewController? = nil) {
        guard let presentingViewController = parentViewController ?? UIApplication.getTopViewController() else {
            print("[Error] TopViewController is nil")
            return
        }

        presentingViewController.presentVCWithModal(self)
    }
    
    // MARK: - Helper Methods
    private func updateTimeDisplays() {
        fromTimeLabel.text = fromTime
        toTimeLabel.text = toTime
    }
    
    private func updatePickerForCurrentField() {
        let timeToEdit = currentEditingField == .from ? fromTime : toTime
        
        if let date = dateFromTimeString(timeToEdit) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.timePicker.setDate(date, animated: true)
            }
        }
    }
    
    // MARK: - Time Conversion Helpers
    private func dateFromTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: timeString) {
            return date
        }
        
        // Fallback: try without space
        formatter.dateFormat = "hh:mma"
        return formatter.date(from: timeString.replacingOccurrences(of: " ", with: ""))
    }
    
    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func setInitialTimes(from: String, to: String) {
        fromTime = from
        toTime = to
        
        // Convert strings to dates
        fromDate = dateFromTimeString(from)
        toDate = dateFromTimeString(to)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.fromTimeLabel.text = from
            self.toTimeLabel.text = to
            
            // Start by editing the "until" field by default
            self.currentEditingField = .until
            self.highlightTextField(self.toTextField, highlight: true)
            self.updatePickerForCurrentField()
        }
    }
    
    func setInitialTimes(from: Date, to: Date) {
        fromDate = from
        toDate = to
        fromTime = timeStringFromDate(from)
        toTime = timeStringFromDate(to)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.fromTimeLabel.text = self.fromTime
            self.toTimeLabel.text = self.toTime
            
            // Start by editing the "until" field by default
            self.currentEditingField = .until
            self.highlightTextField(self.toTextField, highlight: true)
            self.updatePickerForCurrentField()
        }
    }
}

