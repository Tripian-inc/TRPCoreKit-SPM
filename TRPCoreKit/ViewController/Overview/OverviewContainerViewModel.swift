//
//  OverviewContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 15.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation



import UIKit

struct OverViewSection {
    var title: String
    var date: String
    var steps: [TRPStep]
}

protocol OverviewContainerViewModelDelegate: ViewModelDelegate {
    func childOverviewVCLoaded(childVCs: [OverviewViewController])
}

final class OverviewContainerViewModel {
    
    private(set) var tripHash: String
    private var datas: [OverViewSection] = []
    public var tripObserverUseCase: ObserveTripCheckAllPlanUseCase?
    weak var delegate: OverviewContainerViewModelDelegate?
    private(set) var trip: TRPTrip?
    private(set) var dailyPlans  = [TRPPlan]() {
        didSet {
            createData()
            checkGenerated()
        }
    }
    private(set) var childVCs = [OverviewViewController]() {
        didSet {
            delegate?.childOverviewVCLoaded(childVCs: childVCs)
        }
    }
    public var dataIsLoaded = false {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public init(tripHash: String) {
        self.tripHash = tripHash
    }
    
    func start() {
        //delegate?.viewModel(showPreloader: true)
        dataIsLoaded = false
        addObservers()
    }
    
    public func getCurrentStep() -> String {
        return "4"
    }
    
    
    deinit {
        removeObservers()
    }
}

extension OverviewContainerViewModel {
    
    
    func getSectionCount() -> Int {
        return datas.count
    }
    
    func getData(index at: Int) -> OverViewSection {
        return datas[at]
    }
    
    public func getSectionTitle(index at: Int) -> String {
        return datas[at].title
    }
    
    public func getPagingDate(index at: Int) -> String {
        let dailyDate = datas[at].date
        if let date = dailyDate.toDate(format: "yyyy-MM-dd"){
            return date.toString(format: "dd MMM yyyy")
        }
        return dailyDate
    }
    
    private func makeChildOverviewVCs() {
//        if checkAllDatasAdded() {
//            return
//        }
        if datas.count > childVCs.count {
            let data = datas[childVCs.count]
            addChildVC(data: data)
        }
    }
    
    private func checkAllDatasAdded() -> Bool {
        return childVCs.count == datas.count
    }
    
    private func addChildVC(data: OverViewSection) {
        
        DispatchQueue.main.async {
            let viewModel =  OverviewViewModel(dayData: data)
            
            let viewController = UIStoryboard.makeOverviewViewController()
            viewController.viewModel = viewModel
            
            viewModel.delegate = viewController
            self.childVCs.append(viewController)
        }
    }
    
    private func setDatas(datas: [OverViewSection]) {
        self.datas = datas
        makeChildOverviewVCs()
        delegate?.viewModel(dataLoaded: true)
    }
}

extension OverviewContainerViewModel {
    
    private func createData() {
        
        DispatchQueue.main.async {
            var convertedSections = [OverViewSection]()
            for (index,plan) in self.dailyPlans.enumerated() {
                let day = OverViewSection(title: "\(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.day")) \(index + 1)", date: plan.date, steps: plan.steps)
                if !plan.steps.isEmpty {
                    convertedSections.append(day)
                }
            }
            self.setDatas(datas: convertedSections)
        }
    }
    
    private func checkGenerated() {
        guard let trip = trip else { return }
        var allTripGenerated = true
        for plan in trip.plans {
            if plan.generatedStatus == 0 {
                allTripGenerated = false
            }
        }
        
        if allTripGenerated {
            dataIsLoaded = true
            //delegate?.viewModel(showPreloader: false)
        }
    }
}


extension OverviewContainerViewModel: ObserverProtocol {
    
    func addObservers() {
        tripObserverUseCase?.trip.addObserver(self, observer: { [weak self] trip in
            self?.trip = trip
            self?.dailyPlans = trip.plans
        })
    }
    
    func removeObservers() {
        tripObserverUseCase?.trip.removeObserver(self)
    }
    
}
