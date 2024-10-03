//
//  FeatureRequestView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI

enum FeatureSegmentType: String, CaseIterable{
    case open
    case building
    case done
}
struct FeatureRequestView: View {
    @State private var showAddFeatureView = false
    @StateObject var viewModel: FeatureRequestViewModel = FeatureRequestViewModel()
    
    var body: some View {
//        NavigationView {
            VStack {
                picker
                if viewModel.showLoader {
                    Spacer()
                    ProgressView()
                }else {
                    list
                }
                Spacer()
            }
            .background(Color(uiColor: .secondaryBackground))
            .navigationTitle("Feature Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        showAddFeatureView.toggle()
                    }
                }
            }
            Spacer()
            .sheet(isPresented: $showAddFeatureView, content: {
                AddFeatureView()
            })
            .onAppear {
                viewModel.getData()
            }
        
//        }
        
        
    }
    
    var picker : some View {
        Picker("select a segment", selection: $viewModel.selectedSegment) {
            ForEach(FeatureSegmentType.allCases, id: \.self) { segment in
                Text(segment.rawValue)
                    .tag(segment)
            }
        }
//        .background(Color.red)
        .pickerStyle(.segmented)
    }
    
    var list: some View {
        ScrollView {
            ForEach($viewModel.list, id: \.id){ item in
                ListItemView(feature: item.wrappedValue)
                    .onTapGesture {
                        viewModel.userHasVoted(for: item)
                        print("listTapped")
                    }
            }
            .padding(.top, 5)
        }
    }
}

#Preview {
    NavigationView {
        FeatureRequestView()
    }
}


struct ListItemView : View {
    var feature: Feature
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .systemGray), lineWidth: 0.5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.offWhiteAndGray)
                )
            
            HStack {
                ZStack{
                    Group {
                        if feature.hasCurrentUserVoted {
                            Circle()
                                .stroke(Color(uiColor: .darkBlue), lineWidth: 2)
                                 
                        }else {
                            Circle()
                                 .stroke(Color(uiColor: .systemGray), lineWidth: 1)
                        }
                    }
                    .background(Circle().fill(.offWhiteAndGray))
                    .frame(width: 30, height: 30)
                   
                        
                    Group {
                        if feature.hasCurrentUserVoted {
                            Text("\(feature.votedUsers.count)")
                                .foregroundColor(.darkBlue)
                        }else {
                            Text("\(feature.votedUsers.count)")
                                .foregroundColor(Color(uiColor: .label))
                        }
                    }
                        .font(.caption)
                        .fontWeight(.black)
                }
                
                VStack(alignment: .leading){
                    Text(feature.featureTitle)
                        .font(.callout)
                        .fontWeight(.bold)
                    Text(feature.featureDescription)
                        .font(.caption2)
                        .foregroundColor(.darkGray3)
                }
                Spacer()
            }
            .padding(5)
        }
        .padding(.horizontal)
    }
}
