//
//  SettingView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI

struct SettingView: View {
    var  sections: [(header:String, items: [SettingType])] = [
        ("Customization", [.appearance]),
        ("Support", [.featureRequest, .contactUS, .reportAnError]),
        ("Support an Indie Developer", [.leaveReview, .followMe]),
        ("More", [.refferAFriend, .privacyPolicy])
    ]
    
    var body: some View {
        NavigationView {
            List(sections, id: \.header) { section in
                Section {
                    ForEach(section.items, id: \.self){ item in
                       rowView(item: item)
                    }
                    .listRowBackground(Color(uiColor: .offWhiteAndGray))
                    
                } header: {
                    Text(section.header)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    func rowView(item: SettingType) -> some View {
        HStack {
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
            
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}

#Preview {
    SettingView()
}
