import SwiftUI

enum FeatureSegmentType: String, CaseIterable {
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
        .toolbar {
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
        .sheet(isPresented: $showAddFeatureView) {
            AddFeatureView(viewModel: AddFeatureViewModel(existingFeatures: viewModel.list))
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search features")
    }

    private var picker: some View {
        Picker("Segment", selection: $viewModel.selectedSegment) {
            ForEach(FeatureSegmentType.allCases, id: \.self) { segment in
                Text(segment.rawValue.capitalized).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var maxVotes: Int {
        viewModel.list.map { $0.votedUsers.count }.max() ?? 1
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.showLoader {
            Spacer()
            ProgressView().progressViewStyle(.circular)
            Spacer()
        } else if viewModel.list.isEmpty {
            emptyState
        } else {
            featureList
        }
    }

    private var featureList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.list, id: \.id) { feature in
                    ProgressCardView(
                        feature: feature,
                        maxVotes: maxVotes,
                        isInFlight: feature.id.map { viewModel.inFlightVoteIds.contains($0) } ?? false,
                        onVoteTapped: { viewModel.toggleVote(for: feature) }
                    )
                }
            }
            .padding(.top, 4)
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

// MARK: - Progress Card

struct ProgressCardView: View {
    let feature: Feature
    let maxVotes: Int
    var isInFlight: Bool
    var onVoteTapped: () -> Void

    private var votes: Int { feature.votedUsers.count }
    private var progress: Double { maxVotes > 0 ? Double(votes) / Double(maxVotes) : 0 }
    private var isHot: Bool { progress > 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(feature.featureTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(2)
                        if isHot {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(feature.featureDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(2)
                }
                Spacer()
                statusBadge
            }

            HStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(votes) votes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }

            HStack {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onVoteTapped()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: feature.hasCurrentUserVoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text(feature.hasCurrentUserVoted ? "Voted" : "Vote")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(feature.hasCurrentUserVoted ? Color.green.opacity(0.15) : Color(uiColor: .systemGray5)))
                    .foregroundStyle(feature.hasCurrentUserVoted ? .green : .primary)
                }
                .buttonStyle(.plain)
                .disabled(isInFlight)
                .opacity(isInFlight ? 0.6 : 1.0)

                Spacer()

                if let date = ISO8601DateFormatter.cached.date(from: feature.updatedAt) {
                    Text("Updated " + date.relativeDescription)
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(uiColor: .quaternaryLabel)))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    private var barColor: Color {
        switch feature.currentState {
        case .open, .userRequested: return .blue
        case .building: return .orange
        case .completed: return .green
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch feature.currentState {
        case .building:
            Label("Building", systemImage: "hammer.fill")
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
                .foregroundColor(.orange)
                .font(.caption2.weight(.semibold))
        case .completed:
            Label("Done", systemImage: "checkmark.seal.fill")
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.15)))
                .foregroundColor(.green)
                .font(.caption2.weight(.semibold))
        default:
            EmptyView()
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

#if DEBUG
#Preview {
    NavigationView {
        FeatureRequestView(viewModel: FeatureRequestViewModel(isMockData: true))
    }
}
#endif
