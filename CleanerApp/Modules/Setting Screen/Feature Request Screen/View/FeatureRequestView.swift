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
            content
        }
        .padding(.top, 8)
        .background(Color(uiColor: .secondaryBackground))
        .navigationTitle("Feature Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $viewModel.sort) {
                        ForEach(FeatureRequestViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") {
                    showAddFeatureView.toggle()
                }
            }
        }
        .sheet(isPresented: $showAddFeatureView, content: {
            let addVM = AddFeatureViewModel(existingFeatures: viewModel.list)
            AddFeatureView(viewModel: addVM)
        })
        // Native search for a cleaner UI
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search features")
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
            LazyVStack(spacing: 14) {
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
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(uiColor: .quaternaryLabel))
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            HStack(alignment: .top, spacing: 12) {
                voteButton
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(feature.featureTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(2)
                        Spacer()
                        statusBadge
                    }
                    Text(feature.featureDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(3)
                    if let updatedDate = ISO8601DateFormatter.cached.date(from: feature.updatedAt) {
                        Text("Updated " + updatedDate.relativeDescription)
                            .font(.caption)
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(14)
        }
        .padding(.horizontal)
    }
    
    private var voteButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onVoteTapped()
        }) {
            HStack(spacing: 6) {
                Image(systemName: feature.hasCurrentUserVoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                Text("\(feature.votedUsers.count)")
                    .font(.footnote.weight(.bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(feature.hasCurrentUserVoted ? Color.green.opacity(0.15) : Color.clear)
            )
            .overlay(
                Capsule().stroke(Color(uiColor: .systemGray3), lineWidth: feature.hasCurrentUserVoted ? 2 : 1)
            )
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
}

private extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
