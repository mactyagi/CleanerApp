//
//  SettingView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI

struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.sections, id: \.header) { section in
                Section {
                    ForEach(section.items, id: \.self){ item in
                        RowView(item: item, viewModel: viewModel)
                            .addNavigationLink(item: item)
                    }
                    .listRowBackground(Color(uiColor: .offWhiteAndGray))
        
                } header: {
                    Text(section.header)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .background(Color.lightBlueDarkGrey)
        }
        
    }
}


#Preview {
    SettingView()
}



struct RowView: View {
    var item: SettingType
    @ObservedObject var viewModel: SettingViewModel
    var body: some View {
        rowLeadingView(item: item)
    }
    
    func rowLeadingView(item: SettingType) -> some View {
        VStack(alignment:.leading) {
            Text(item.model.title)
                .font(.headline)
            if !item.model.subTitle.isEmpty{
                Text(item.model.subTitle)
                    .font(.caption2)
                    .foregroundStyle(Color.init(uiColor: .darkGray3))
            }else {
                EmptyView()
            }
        }
    }
    
    
    var menu: some View {
        Menu {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.appearanceMode = mode
                    applyAppearanceMode(mode)
                } label: {
                    HStack {
                        Text(mode.rawValue)
                        if mode == viewModel.appearanceMode{
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
        } label: {
            HStack{
                Text(viewModel.appearanceMode.rawValue)
                Image(systemName: "chevron.up.chevron.down")
            }
            .foregroundColor(.gray)
            .font(.caption)
        }
    }
    
    private func applyAppearanceMode(_ mode: AppearanceMode) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.changeAppearance(to: mode)
            }
    }
}


extension RowView {
    @ViewBuilder
    func addNavigationLink(item: SettingType) -> some View {
        
        switch item {
        case .appearance:
            HStack {
                self
                Spacer()
                HStack{
                    menu
                }
            }
            
        default:
            NavigationLink {
                destinationView(item: item)
            } label: {
                HStack {
                    self
                }
            }
        }
    }
    
    @ViewBuilder
    func destinationView(item: SettingType) -> some View {
        switch item {
        case .featureRequest:
            FeatureRequestView()
        case .privacyPolicy:
            PrivacyPolicyViewControllerWrapper()
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            Text("Unknown Destination")
        }
    }
}
