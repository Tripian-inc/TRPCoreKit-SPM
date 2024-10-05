//
//  CreateTripStayShareViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 5.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPDataLayer
import TRPFoundationKit

protocol CreateTripStayShareViewModelDelegate: ViewModelDelegate {
    func travelCompanionsNotEqual()
    func companionRemoved(_ companion: TRPCompanion)
}

class CreateTripStayShareViewModel {
    
    public enum CellContentType {
        case adultNumber, childNumber, accommodation, companion, selectedCompanions, createCompanion
    }
    
    var sectionModels: [CreateTripStayShareSectionModel] = []
    
    weak var delegate: CreateTripStayShareViewModelDelegate?
    
    private var tripProfile: TRPTripProfile
    private var oldTripProfile: TRPTripProfile?
    
    //USE CASES
    public var observeCompanionUseCases: ObserveCompanionUseCase?
    
    private var adultCount = 1
    private var childCount = 0
    private var selectedTravelCompanions: [TRPCompanion]? {
        didSet {
            checkTravelCompanionsEqualty()
        }
    }
    private var isShowCompanionWarning = false
    private var stayAddress: TRPAccommodation?
        
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil) {
        self.tripProfile = tripProfile
        self.oldTripProfile = oldTripProfile
        implementTripProfile(oldTripProfile)
        createData()
    }
        
    func start() {
        observeCompanionUseCases?.values.addObserver(self, observer: { [weak self] companions in
            if let profile = self?.oldTripProfile {
                var selectedCompanions = [TRPCompanion]()
                for id in profile.companionIds {
                    if let companion = companions.first(where: {$0.id == id}) {
                        selectedCompanions.append(companion)
                    }
                }
                if !selectedCompanions.isEmpty {
                    self?.addTravellerCompanions(selectedCompanions)
                }
            }
        })
    }
    
    func getSectionCount() -> Int{
        return sectionModels.count
    }
    
    func getCellCount(section: Int) -> Int{
        return sectionModels[section].cells.count
    }
    
    func getSectionTitle(section: Int) -> String {
        return sectionModels[section].title
    }
    
    func getSectionIsRequired(section: Int) -> Bool {
        return sectionModels[section].isRequired
    }
    
    func getCellModel(at indexPath: IndexPath) -> CreateTripStayShareCellModel {
        return sectionModels[indexPath.section].cells[indexPath.row]
    }
}

extension CreateTripStayShareViewModel {
    
    private func createData() {
        var sections = [CreateTripStayShareSectionModel]()
        let personCell = CreateTripStayShareCellModel(title: "Adults", contentType: .adultNumber)
        let childCell = CreateTripStayShareCellModel(title: "Children", contentType: .childNumber)
        sections.append(CreateTripStayShareSectionModel(title: "Traveler Info", cells: [personCell, childCell]))
//        sections.append(CreateTripStayShareSectionModel(title: "Children", cells: [childCell]))
        let accommodationCell = CreateTripStayShareCellModel(title: "Enter your hotel/homeshare address", contentType: .accommodation)
        sections.append(CreateTripStayShareSectionModel(title: "Where will you stay?", cells: [accommodationCell], isRequired: true))
        let companionCell = CreateTripStayShareCellModel(title: "Add companion", contentType: .companion)
        let createCompanionCell = CreateTripStayShareCellModel(title: "Create a companion profile", contentType: .createCompanion)
        var sectionModel = CreateTripStayShareSectionModel(title: "Who are you travelling with", cells: [companionCell, createCompanionCell])
        if getSelectedCompanions().count > 0 {
            let selectedCompanionsCell = CreateTripStayShareCellModel(title: "", contentType: .selectedCompanions)
            sectionModel = CreateTripStayShareSectionModel(title: "Who are you travelling with", cells: [companionCell, selectedCompanionsCell, createCompanionCell])
        }
        sections.append(sectionModel)
        sectionModels = sections
    }
}

//MARK: - EDIT TRIP
extension CreateTripStayShareViewModel {
    
    private func implementTripProfile(_ tripProfile: TRPTripProfile?) {
        
        guard let profile = tripProfile else {return}
                        
        self.childCount = profile.numberOfChildren
        self.adultCount = profile.numberOfAdults
        
        if let accommondation = profile.accommodation {
            stayAddress = accommondation
        }
    }
    
}

//MARK: - Traveler Counts
extension CreateTripStayShareViewModel {
    
    public func getAdultCount() -> Int {
        return adultCount
    }
    
    public func setAdultCount(_ count: Int) {
        self.adultCount = count
    }
    
    public func getChildCount() -> Int {
        return childCount
    }
    
    public func setChildCount(_ count: Int) {
        self.childCount = count
    }
}

//MARK: - Companion
extension CreateTripStayShareViewModel {
    
    public func addTravellerCompanions(_ selectedCompanion: [TRPCompanion]) {
        selectedTravelCompanions = selectedCompanion
        createData()
        delegate?.viewModel(dataLoaded: true)
    }
    
    private func checkTravelCompanionsEqualty() {
        guard let companionCount = selectedTravelCompanions?.count else {return}
        let peopleCount = adultCount + childCount + 1
        if peopleCount < companionCount {
            if !isShowCompanionWarning {
                isShowCompanionWarning.toggle()
                delegate?.travelCompanionsNotEqual()
            }
        }
    }
    
    public func getSelectedCompanionIds() -> [Int] {
        return selectedTravelCompanions?.compactMap({$0.id}) ?? []
    }
    
    public func getSelectedCompanions() -> [TRPCompanion] {
        return selectedTravelCompanions ?? []
    }
    
    public func getSelectedCompanionTagModel() -> [SelectedItemTagModel] {
        return selectedTravelCompanions?.compactMap({SelectedItemTagModel(id: $0.id, title: $0.name)}) ?? []
    }
    
    public func removeTravellerCompanion(_ id: Int) {
        if let companion = selectedTravelCompanions?.first(where: {$0.id == id}) {
            selectedTravelCompanions?.remove(element: companion)
            createData()
            delegate?.viewModel(dataLoaded: true)
            delegate?.companionRemoved(companion)
        }
    }
}

//MARK: - Accommodation
extension CreateTripStayShareViewModel {
    public func getStayAddressName() -> String {
        return stayAddress?.name ?? ""
    }
    
    public func setStayAddress(_ address: TRPAccommodation?) {
        stayAddress = address
        delegate?.viewModel(dataLoaded: true)
    }
}

extension CreateTripStayShareViewModel {
    
    public func canContinue() -> Bool {
        guard stayAddress != nil else {
            self.delegate?.viewModel(showMessage: "Please select where will you stay", type: .error)
            return false
        }
        setTripProperties()
        return true
    }
    
    public func setTripProperties() {
        
        tripProfile.numberOfAdults = adultCount
        tripProfile.numberOfChildren = childCount
        
        if let companions = selectedTravelCompanions {
            tripProfile.companionIds = companions.map{$0.id}
        }
        
        if let stayAddress = stayAddress {
            tripProfile.accommodation = TRPAccommodation(name: stayAddress.name,
                                                         referanceId: stayAddress.referanceId,
                                                         address: stayAddress.address,
                                                         coordinate: stayAddress.coordinate)
        } else {
            tripProfile.accommodation = nil
        }
    }
}


struct CreateTripStayShareSectionModel {
    var title: String
    var cells: [CreateTripStayShareCellModel]
    var isRequired: Bool = false
}
struct CreateTripStayShareCellModel {
    var title: String
    var contentType: CreateTripStayShareViewModel.CellContentType
}
