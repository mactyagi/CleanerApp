import SwiftUI

struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()

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

                        VStack(spacing: 10) {
                            ForEach(section.items, id: \.self) { item in
                                SettingRowView(item: item, viewModel: viewModel)
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

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

            Text("CleanerApp")
                .font(.title2)
                .fontWeight(.bold)

            Text("Version 1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        Group {
            if item == .appearance {
                appearanceRow
            } else {
                NavigationLink {
                    destinationView(item: item)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    rowContent
                }
            }
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

    private var appearanceRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.accentColor)
            }

            Text(item.model.title)
                .font(.headline)
                .foregroundStyle(item.accentColor)

            Spacer()

            Menu {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.appearanceMode = mode
                        applyAppearanceMode(mode)
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if mode == viewModel.appearanceMode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.appearanceMode.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundColor(.gray)
                .font(.caption)
            }
        }
    }

    private func applyAppearanceMode(_ mode: AppearanceMode) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.changeAppearance(to: mode)
        }
    }

    @ViewBuilder
    func destinationView(item: SettingType) -> some View {
        switch item {
        case .featureRequest:
            FeatureRequestView(viewModel: FeatureRequestViewModel())
        case .privacyPolicy:
            PrivacyPolicyView()
        default:
            Text("Coming Soon")
        }
    }
}
