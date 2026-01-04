//
//  SettingView.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI
import StoreKit

struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            List(viewModel.sections, id: \.header) { section in
                Section {
                    ForEach(section.items, id: \.self){ item in
                        RowView(item: item, viewModel: viewModel, showShareSheet: $showShareSheet)
                            .addNavigationLink(item: item)
                    }
                    .listRowBackground(Color(uiColor: .offWhiteAndGray))

                } header: {
                    Text(section.header)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .background(Color.lightBlueDarkGrey)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!])
            }
        }

    }
}


#Preview {
    SettingView()
}



struct RowView: View {
    var item: SettingType
    @ObservedObject var viewModel: SettingViewModel
    @Binding var showShareSheet: Bool

    var body: some View {
        rowLeadingView(item: item)
    }

    func rowLeadingView(item: SettingType) -> some View {
        VStack(alignment:.leading) {
            Text(item.model.title)
                .font(.headline)
            if !item.model.subTitle.isEmpty{
                Text(item.model.subTitle)
                    .font(.caption2)
                    .foregroundStyle(Color.init(uiColor: .darkGray3))
            }else {
                EmptyView()
            }
        }
    }


    var menu: some View {
        Menu {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.appearanceMode = mode
                    applyAppearanceMode(mode)
                } label: {
                    HStack {
                        Text(mode.rawValue)
                        if mode == viewModel.appearanceMode{
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

        } label: {
            HStack{
                Text(viewModel.appearanceMode.rawValue)
                Image(systemName: "chevron.up.chevron.down")
            }
            .foregroundColor(.gray)
            .font(.caption)
        }
    }

    private func applyAppearanceMode(_ mode: AppearanceMode) {
        // Save to UserDefaults - SwiftUI's @AppStorage in AppearanceManager will react automatically
        UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
    }

    // MARK: - Action Handlers

    private func openLinkedIn() {
        if let url = URL(string: "https://www.linkedin.com/in/manukant-tyagi/") {
            UIApplication.shared.open(url)
        }
    }

    private func openEmail(subject: String) {
        let email = "support@cleanerapp.com"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}


extension RowView {
    @ViewBuilder
    func addNavigationLink(item: SettingType) -> some View {

        switch item {
        case .appearance:
            HStack {
                self
                Spacer()
                HStack{
                    menu
                }
            }

        case .followMe:
            Button {
                openLinkedIn()
            } label: {
                HStack {
                    self
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

        case .contactUS:
            Button {
                openEmail(subject: "CleanerApp - Contact Us")
            } label: {
                HStack {
                    self
                    Spacer()
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

        case .reportAnError:
            Button {
                openEmail(subject: "CleanerApp - Bug Report")
            } label: {
                HStack {
                    self
                    Spacer()
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

        case .leaveReview:
            Button {
                requestAppReview()
            } label: {
                HStack {
                    self
                    Spacer()
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

        case .refferAFriend:
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    self
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

        default:
            NavigationLink {
                destinationView(item: item)
            } label: {
                HStack {
                    self
                }
            }
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
            Text("Unknown Destination")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
