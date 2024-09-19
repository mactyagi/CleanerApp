//
//  AddFeatureView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 18/09/24.
//

import SwiftUI
import AlertToast

struct AddFeatureView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var viewModel = AddFeatureViewModel()
    @State var showLoader = false
    @State var showCompletionAlert = false
    @State var showErrorAlert = false
    @FocusState private var isTitleFocused: Bool
//    @State private var title: String = ""
//    @State private var subtitle: String = ""
    var body: some View {
        
        ZStack {
            Color.red.ignoresSafeArea()
            NavigationView {
                mainContent
                    .navigationTitle("Request a feature")
                        .background(Color.secondaryBackground)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Send") {
                                hideKeyboard()
                                showLoader = true
                                viewModel.sendFeatureToFirebase {success in
                                    showLoader = false
                                    if success {
                                        showCompletionAlert = true
                                    }else{
                                        showErrorAlert = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(
                                viewModel.title.isEmpty || viewModel.description.isEmpty
                            )
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            }
            
            if showLoader {
                ZStack {
                    Color.gray.opacity(0.5)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                    if showLoader {
                        ProgressView()
                    }
                }
            }
        }
        
        .toast(isPresenting: $showErrorAlert) {
            AlertToast(displayMode: .alert, type: .error(.red))
        } onTap: {
            showErrorAlert = false
        }
        
        .toast(isPresenting: $showCompletionAlert) {
            AlertToast(displayMode: .alert, type: .complete(.darkBlue))
        } onTap: {
            showCompletionAlert = false
        }
        
        .onAppear{
            isTitleFocused = true
        }

    }
    
    var mainContent: some View {
        ZStack {
            VStack{
                Text("Make the title and Description as clear as possible to help me understand your request and get more visiblity by other users 😊")
                    .font(.headline)
                    .foregroundColor(.darkGray3)
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Title")
                    TextField("What would you like to see", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTitleFocused)
                }
                .font(.caption)
                .padding(.vertical)
                
                VStack(alignment: .leading) {
                    Text("Description")
                    TextField("A more in-Depth Description", text: $viewModel.description)
                        .textFieldStyle(.roundedBorder)
                }
                .font(.caption)
                
                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    AddFeatureView()
}
