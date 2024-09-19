//
//  FeatureRequestView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI

struct FeatureRequestView: View {
    @State private var selectedSegment = 0
    @State private var showAddFeatureView = false
    let segments = ["Open", "Building", "Done"]
    let listElement: [(title: String, substring: String)] = [("TITle 1","Subtitle 2"), ("TITle 1","Subtitle 2")]
    
    var body: some View {
//        NavigationView {
            VStack {
                picker
                list
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
//        }
        
        
    }
    
    var picker : some View {
        Picker("select a segment", selection: $selectedSegment) {
            ForEach(0 ..< segments.count, id: \.self) { index in
                Text(segments[index])
                    .tag(index)
            }
        }
//        .background(Color.red)
        .pickerStyle(.segmented)
    }
    
    var list: some View {
        ScrollView {
            ForEach(listElement, id: \.title){ item in
                    ListItemView()
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
                   Circle()
                        .stroke(Color(uiColor: .systemGray), lineWidth: 1)
                        .background(Circle().fill(.offWhiteAndGray))
                        .frame(width: 30, height: 30)
                        
                        
                    Text("10")
                        .font(.caption)
                        .fontWeight(.black)
//                        .foregroundColor(.white)
                }
                VStack(alignment: .leading){
                    Text("Title")
                        .font(.callout)
                        .fontWeight(.bold)
                    Text("Subtitle")
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
