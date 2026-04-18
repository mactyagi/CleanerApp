import SwiftUI

struct AppearanceView: View {
    @ObservedObject var viewModel: SettingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(heroAccentColor.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: heroIconName)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(heroAccentColor)
                            .contentTransition(.symbolEffect(.replace))
                    }

                    Text(viewModel.appearanceMode.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())

                    Text("Current appearance mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .offWhiteAndGray))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    heroPill(mode: .system, icon: "gearshape.fill")
                    heroPill(mode: .light, icon: "sun.max.fill")
                    heroPill(mode: .dark, icon: "moon.fill")
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color.lightBlueDarkGrey)
        .navigationTitle("Appearance")
    }

    private func selectMode(_ mode: AppearanceMode) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.appearanceMode = mode
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.changeAppearance(to: mode)
        }
    }

    private func heroPill(mode: AppearanceMode, icon: String) -> some View {
        let isSelected = viewModel.appearanceMode == mode

        return Button {
            selectMode(mode)
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

    private var heroIconName: String {
        switch viewModel.appearanceMode {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gearshape.fill"
        }
    }

    private var heroAccentColor: Color {
        switch viewModel.appearanceMode {
        case .light: return .orange
        case .dark: return .indigo
        case .system: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView(viewModel: SettingViewModel())
    }
}
