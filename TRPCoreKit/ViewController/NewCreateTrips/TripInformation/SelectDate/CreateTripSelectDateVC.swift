//
//  CreateTripSelectDateVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit
import FSCalendar
protocol CreateTripSelectDateVCDelegate: AnyObject {
    func createTripSelectDateVCArrivalSelected(date: Date)
    func createTripSelectDateVCDepartureSelected(date: Date)
}
@objc(SPMCreateTripSelectDateVC)
class CreateTripSelectDateVC: TRPBaseUIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var titleLabel: UILabel!
    
    public var viewModel: CreateTripSelectDateViewModel!
    public weak var delegate: CreateTripSelectDateVCDelegate?
    
    private var firstDate: Date?
    private var lastDate: Date?
    private var datesRange: [Date]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCalendar()
        selectDate()
        titleLabel.font = trpTheme.font.header2
        titleLabel.text = viewModel.getTitle()
    }
    
    private func setupCalendar() {
        calendarView.placeholderType = .none
        calendarView.today = nil
        calendarView.allowsMultipleSelection = isDateRangeSelectionActive()
        calendarView.locale = Locale(identifier: TRPClient.shared.language)
    }
    
    private func isDateRangeSelectionActive() -> Bool {
        return false
    }
    
    private func selectDate() {
        calendarView.select(viewModel.getSelectedDate())
    }

}

extension CreateTripSelectDateVC: FSCalendarDataSource, FSCalendarDelegate {
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        return viewModel.getMinimumSelectableDate()
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        return viewModel.getMaximumSelectableDate()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        guard isDateRangeSelectionActive() else {
            let date = date.localDate()
            if viewModel.isArrival {
                self.delegate?.createTripSelectDateVCArrivalSelected(date: date)
            } else {
                self.delegate?.createTripSelectDateVCDepartureSelected(date: date)
            }
            self.dismiss(animated: true)
            return
        }
        
        if firstDate == nil {
            firstDate = date
            datesRange = [firstDate!]
            return
        }

        if firstDate != nil && lastDate == nil {
            if date <= firstDate! {
                calendar.deselect(firstDate!)
                firstDate = date
                datesRange = [firstDate!]
                return
            }

            let range = viewModel.datesRange(from: firstDate!, to: date)
            lastDate = range.last

            for d in range {
                calendar.select(d)
            }

            datesRange = range
            return
        }

        if firstDate != nil && lastDate != nil {
            for d in calendar.selectedDates {
                calendar.deselect(d)
            }

            lastDate = nil
            firstDate = nil

            datesRange = []

            print("datesRange contains: \(datesRange!)")
        }
    }

    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        guard isDateRangeSelectionActive() else {return}
        if firstDate != nil && lastDate != nil {
            for d in calendar.selectedDates {
                calendar.deselect(d)
            }

            lastDate = nil
            firstDate = nil

            datesRange = []
            print("datesRange contains: \(datesRange!)")
        }
    }
}
