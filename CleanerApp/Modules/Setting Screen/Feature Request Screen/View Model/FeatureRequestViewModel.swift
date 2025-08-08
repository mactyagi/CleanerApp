//
//  FeatureRequestViewModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 29/09/24.
//

import SwiftUI


class FeatureRequestViewModel: ObservableObject {
    
    private var allData: [Feature] = []
    @Published var list : [Feature] = []
    @Published var showLoader: Bool = false
    @Published var selectedSegment: FeatureSegmentType = .open {
        didSet{
            getfilteredData()
        }
    }
    
    init(isMockData: Bool = false) {
        if  isMockData {
            getMockData()
        }else {
            getData()
        }
    }
    
    
    func getMockData() {
        allData = Feature.mockFeatures()
        getfilteredData()
    }
    
    func getData() {
        showLoader = true
        FireStoreManager().fetchFeatures { features in
            self.allData = features
            self.showLoader = false
            self.getfilteredData()
        }
    }
    
    func getfilteredData() {
        switch selectedSegment {
        case .open:
            list = allData.filter { $0.currentState == .open }
        case .building:
            list = allData.filter { $0.currentState == .building }
        case .done:
            list = allData.filter { $0.currentState == .completed }
        }
        
    }
    
    func userHasVoted(for feature: Binding<Feature>) {
        
        if feature.wrappedValue.hasCurrentUserVoted {
            feature.wrappedValue.votedUsers.remove(getDeviceIdentifier() ?? "")
        }else {
            feature.wrappedValue.votedUsers.insert(getDeviceIdentifier() ?? "")
        }
        
        FireStoreManager().updateFeature(feature: feature.wrappedValue) { success in
            if !success {
                logErrorString(errorString: "Update feature failed", VCName: "FeatureRequestViewModel", functionName: #function, line: #line)
            }
        }
    }
}
