//
//  SettingView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI





struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()
    @State private var showReferAFriendSheet = false
    var body: some View {
        NavigationView {
            List(viewModel.sections, id: \.header) { section in
                Section {
                    ForEach(section.items, id: \.self){ item in
                        row(type: item)
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
    
    
    @ViewBuilder
    func row(type:SettingType) -> some View{
        switch type {
        case .appearance:
            RowView(item: .appearance, viewModel: viewModel)
                .addAppearanceMenu()
        case .refferAFriend:
            referAFriendView
        case .reportAnError:
            RowView(item: .reportAnError, viewModel: viewModel)
                .addNavigationLink()
        case .featureRequest:
            RowView(item: .featureRequest, viewModel: viewModel)
                .addNavigationLink()
            
        default:
            RowView(item: type, viewModel: viewModel)
        }
    }
    
    var referAFriendView: some View {
        Button {
            showReferAFriendSheet.toggle()
        } label: {
            RowView(item: .refferAFriend, viewModel: viewModel)
        }
        .sheet(isPresented: $showReferAFriendSheet) {
            ReferAFriendView(shareText: "Check out this amazing app!", appLink: URL(string: "https://apps.apple.com/in/app/space-cleaner-all-in-one/id6478117627")!)
                .presentationDetents([.medium])
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
                .foregroundColor(Color(UIColor.label))
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
    func addNavigationLink() -> some View {
        NavigationLink {
            destinationView(item: self.item)
        } label: {
            HStack {
                self
            }
        }
    }
    
    
    @ViewBuilder
    func addAppearanceMenu() -> some View {
        HStack {
            self
            Spacer()
            HStack{
                menu
            }
        }
    }
    
    @ViewBuilder
    func destinationView(item: SettingType) -> some View {
        
        switch item {
        case .featureRequest:
            FeatureRequestView()
        case .reportAnError:
            ReportErrorViewControllerWrapper()
                .foregroundStyle(.darkBlue)
        default:
            Text("Unknown Destination")
        }
    }
}
