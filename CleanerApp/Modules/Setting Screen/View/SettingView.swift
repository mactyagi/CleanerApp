import SwiftUI

struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()
    @State private var showingAppearance = false
    @State private var revertTask: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                ForEach(viewModel.sections, id: \.header) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.header.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        if section.header == "Customization" {
                            appearancePills
                        }

                        VStack(spacing: 10) {
                            ForEach(section.items, id: \.self) { item in
                                if item == .appearance {
                                    EmptyView()
                                } else {
                                    SettingRowView(item: item, viewModel: viewModel)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.lightBlueDarkGrey)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Card

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [currentAccentColor, currentAccentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: currentIconName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: currentAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(currentTitle)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())

            Text(currentSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .offWhiteAndGray))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var currentIconName: String {
        guard showingAppearance else { return "sparkles" }
        switch viewModel.appearanceMode {
        case .system: return "gearshape.fill"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    private var currentAccentColor: Color {
        guard showingAppearance else { return .blue }
        switch viewModel.appearanceMode {
        case .system: return .gray
        case .light: return .orange
        case .dark: return .indigo
        }
    }

    private var currentTitle: String {
        guard showingAppearance else { return "CleanerApp" }
        switch viewModel.appearanceMode {
        case .system: return "System"
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }

    private var currentSubtitle: String {
        guard showingAppearance else { return "Version 1.0" }
        switch viewModel.appearanceMode {
        case .system: return "Follows device setting"
        case .light: return "Bright and clear"
        case .dark: return "Easy on the eyes"
        }
    }

    // MARK: - Appearance Pills

    private var appearancePills: some View {
        HStack(spacing: 10) {
            appearancePill(mode: .system, icon: "gearshape.fill")
            appearancePill(mode: .light, icon: "sun.max.fill")
            appearancePill(mode: .dark, icon: "moon.fill")
        }
        .padding(.horizontal, 16)
    }

    private func appearancePill(mode: AppearanceMode, icon: String) -> some View {
        let isSelected = viewModel.appearanceMode == mode

        return Button {
            revertTask?.cancel()

            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.appearanceMode = mode
                showingAppearance = true
            }
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = scene.delegate as? SceneDelegate {
                sceneDelegate.changeAppearance(to: mode)
            }
            let task = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingAppearance = false
                }
            }
            revertTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(mode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(uiColor: .offWhiteAndGray))
                    .shadow(color: .black.opacity(isSelected ? 0.15 : 0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingView()
    }
}

private struct SettingRowView: View {
    let item: SettingType
    @ObservedObject var viewModel: SettingViewModel

    var body: some View {
        NavigationLink {
            destinationView(item: item)
                .toolbar(.hidden, for: .tabBar)
        } label: {
            rowContent
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(uiColor: .offWhiteAndGray))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.model.title)
                    .font(.headline)
                    .foregroundStyle(item.accentColor)
                if !item.model.subTitle.isEmpty {
                    Text(item.model.subTitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .darkGray3))
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    func destinationView(item: SettingType) -> some View {
        switch item {
        case .appearance:
            AppearanceView(viewModel: viewModel)
        case .featureRequest:
            FeatureRequestView(viewModel: FeatureRequestViewModel())
        case .contactUS:
            ContactUsView()
        case .privacyPolicy:
            PrivacyPolicyView()
        default:
            Text("Coming Soon")
        }
    }
}
