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
    @StateObject var viewModel: FeatureRequestViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            picker
            searchAndSort
            content
        }
        .padding(.top, 8)
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
        .sheet(isPresented: $showAddFeatureView, content: {
            AddFeatureView()
        })
        // Fetch is triggered in FeatureRequestViewModel.init
    }
    
    private var picker : some View {
        Picker("select a segment", selection: $viewModel.selectedSegment) {
            ForEach(FeatureSegmentType.allCases, id: \.self) { segment in
                Text(segment.rawValue.capitalized)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    private var searchAndSort: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search features", text: $viewModel.searchText)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(true)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .tertiarySystemBackground)))
            
            Menu {
                Picker("Sort", selection: $viewModel.sort) {
                    ForEach(FeatureRequestViewModel.SortOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sort.title)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .quaternaryLabel)))
            }
            .fixedSize()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.showLoader {
            simpleLoader
        } else if viewModel.list.isEmpty {
            emptyState
        } else {
            list
        }
    }
    
    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.list, id: \.id) { feature in
                    ListItemView(
                        feature: feature,
                        isInFlight: feature.id.map { viewModel.inFlightVoteIds.contains($0) } ?? false,
                        onVoteTapped: { viewModel.toggleVote(for: feature) }
                    )
                }
            }
            .padding(.top, 4)
        }
    }
    
    private var simpleLoader: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No features here yet")
                .font(.headline)
            Text(viewModel.selectedSegment == .open ? "Request a feature or try another tab." : "Nothing in this state.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if viewModel.selectedSegment == .open {
                Button(action: { showAddFeatureView = true }) {
                    Label("Request a feature", systemImage: "plus.circle")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        FeatureRequestView(viewModel: FeatureRequestViewModel(isMockData: true))
    }
}
#endif


struct ListItemView : View {
    var feature: Feature
    var isInFlight: Bool
    var onVoteTapped: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .quaternaryLabel))
                )
            HStack(alignment: .top, spacing: 12) {
                voteButton
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(feature.featureTitle)
                            .font(.callout.weight(.semibold))
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(2)
                        Spacer()
                        statusBadge
                    }
                    Text(feature.featureDescription)
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(3)
                    if let updatedDate = ISO8601DateFormatter.cached.date(from: feature.updatedAt) {
                        Text("Updated " + updatedDate.relativeDescription)
                            .font(.caption2)
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(12)
        }
        .padding(.horizontal)
    }
    
    private var voteButton: some View {
        Button(action: onVoteTapped) {
            ZStack {
                Circle()
                    .strokeBorder(borderColor, lineWidth: feature.hasCurrentUserVoted ? 2 : 1)
                    .background(Circle().fill(fillColor))
                    .frame(width: 36, height: 36)
                Text("\(feature.votedUsers.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(uiColor: .label))
            }
        }
        .buttonStyle(.plain)
        .disabled(isInFlight)
        .opacity(isInFlight ? 0.6 : 1.0)
        .accessibilityLabel(Text("Vote, \(feature.votedUsers.count) votes, \(feature.hasCurrentUserVoted ? "selected" : "not selected")"))
    }
    
    private var statusBadge: some View {
        Group {
            switch feature.currentState {
            case .building:
                Label("Building", systemImage: "hammer.fill")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundColor(.orange)
                    .font(.caption2.weight(.semibold))
            case .completed:
                Label("Done", systemImage: "checkmark.seal.fill")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .foregroundColor(.green)
                    .font(.caption2.weight(.semibold))
            default:
                EmptyView()
            }
        }
    }
    
    private var borderColor: Color { Color(uiColor: .systemGray) }
    private var fillColor: Color { feature.hasCurrentUserVoted ? Color(uiColor: .systemGreen).opacity(0.25) : Color.clear }
}

private extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
