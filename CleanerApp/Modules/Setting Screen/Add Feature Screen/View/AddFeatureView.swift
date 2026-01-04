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
    @ObservedObject private var viewModel: AddFeatureViewModel
    @FocusState private var isTitleFocused: Bool
    
    init(viewModel: AddFeatureViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .secondaryBackground).ignoresSafeArea()
            NavigationView {
                mainContent
                    .navigationTitle("Request a feature")
                    .background(Color(uiColor: .secondaryBackground))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Send") {
                                hideKeyboard()
                                viewModel.submitFeature {
                                    dismiss()
                                }
                            }
                            .font(.headline)
                            .foregroundColor(Color(uiColor: .darkBlue))
                            .disabled(!viewModel.isFormValid)
                            .opacity(viewModel.isFormValid ? 1.0 : 0.5)
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundColor(Color(uiColor: .darkGray3))
                        }
                    }
            }
            
            if viewModel.isLoading {
                ZStack {
                    Color(uiColor: .veryLightBlueAndDarkGray).opacity(0.7)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(uiColor: .darkBlue))
                }
            }
        }
        
        .toast(isPresenting: $viewModel.showErrorAlert) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Something went wrong")
        } onTap: {
            viewModel.resetAlerts()
        }
        
        .toast(isPresenting: $viewModel.showCompletionAlert) {
            AlertToast(displayMode: .alert, type: .complete(.darkBlue))
        } onTap: {
            viewModel.resetAlerts()
        }
        
        .onAppear{
            isTitleFocused = true
        }
    }
    
    var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionCard
                titleInputField
                descriptionInputField
                suggestionsSection
                Spacer(minLength: 0)
            }
            .padding()
        }
    }
    
    var instructionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .systemGray5), lineWidth: 0.5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .offWhiteAndGray))
                )
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Feature Request Instructions")
                    .font(.headline)
                    .foregroundColor(Color(uiColor: .darkBlue))
                    .padding(.bottom, 2)
                
                Text("Make the title and description as clear as possible to help me understand your request and get more visibility by other users 😊")
                    .font(.callout)
                    .foregroundColor(Color(uiColor: .darkGray3))
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
    }
    
    var titleInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkGray3))
                Spacer()
                Text("\(viewModel.title.count)/\(viewModel.maxTitleLength)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField("What would you like to see", text: $viewModel.title)
                .focused($isTitleFocused)
                .padding(10)
                .font(.body)
                .background(Color.whiteAndGray2)
                .background(in: .buttonBorder)
            
            if viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).count < viewModel.minTitleLength {
                Text("Title should be at least \(viewModel.minTitleLength) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var descriptionInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkGray3))
                Spacer()
                Text("\(viewModel.description.count)/\(viewModel.maxDescriptionLength)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.description)
                    .padding(5)
                    .font(.body)
                    .background(Color.clear)
                    .background(in: .buttonBorder)
                    .overlay(
                        Group {
                            if viewModel.description.isEmpty {
                                Text("A more in-depth description")
                                    .font(.body)
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(10)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
            }
            .frame(height: 150)
            
            if viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).count < viewModel.minDescriptionLength {
                Text("Description should be at least \(viewModel.minDescriptionLength) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    var suggestionsSection: some View {
        if !viewModel.suggestedFeatures.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Similar requests")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(uiColor: .darkGray3))
                ForEach(viewModel.suggestedFeatures, id: \.id) { feature in
                    HStack(spacing: 10) {
                        Text(feature.featureTitle)
                            .font(.callout)
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(1)
                        Spacer()
                        Label("\(feature.votedUsers.count)", systemImage: "hand.thumbsup.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .labelStyle(.titleAndIcon)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(uiColor: .systemGray5), lineWidth: 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(uiColor: .offWhiteAndGray))
                            )
                    )
                }
            }
        } else {
            EmptyView()
        }
    }
}

// Extension to hide keyboard
extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    AddFeatureView(viewModel: AddFeatureViewModel(existingFeatures: Feature.mockFeatures()))
}
