import SwiftUI
import MessageUI
import UIKit

struct ContactUsView: View {
    @State private var showMailCompose = false
    @State private var showMailUnavailableAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                emailCard
                linkedInCard
            }
            .padding(.top, 20)
        }
        .background(Color.lightBlueDarkGrey)
        .navigationTitle("Contact Us")
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipient: "mactyagi@icloud.com",
                subject: "CleanerApp Support",
                body: deviceInfoBody
            )
        }
        .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
            Button("Copy Email") {
                UIPasteboard.general.string = "mactyagi@icloud.com"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mail is not set up on this device. The email address has been copied to your clipboard.")
        }
    }

    private var emailCard: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                showMailCompose = true
            } else {
                if let url = URL(string: "mailto:mactyagi@icloud.com?subject=CleanerApp%20Support") {
                    UIApplication.shared.open(url)
                } else {
                    showMailUnavailableAlert = true
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Send an Email")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("mactyagi@icloud.com")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .darkGray3))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: .offWhiteAndGray))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }

    private var linkedInCard: some View {
        Button {
            if let url = URL(string: "https://www.linkedin.com/in/manukant-tyagi") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect on LinkedIn")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                    Text("linkedin.com/in/manukant-tyagi")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .darkGray3))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: .offWhiteAndGray))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }

    private var deviceInfoBody: String {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return """


        --- Device Info ---
        App Version: \(appVersion) (\(buildNumber))
        Device: \(device.model)
        iOS Version: \(device.systemVersion)
        """
    }
}

private struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ContactUsView()
    }
}
