//
//  ContactsFlowViews.swift
//  CleanerApp
//
//  Pure SwiftUI views for Contacts navigation flow
//

import SwiftUI
import Contacts

// MARK: - Contacts Flow View (Without its own NavigationStack)
struct ContactsFlowView: View {
    @ObservedObject var viewModel: OrganizeContactViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        OrganizeContactsView(
            viewModel: viewModel,
            onDuplicatesTapped: { path.append(ContactsDestination.duplicates) },
            onIncompleteTapped: { path.append(ContactsDestination.incomplete) },
            onBackupTapped: { path.append(ContactsDestination.backup) },
            onAllContactsTapped: { path.append(ContactsDestination.allContacts) }
        )
        .task {
            await viewModel.getData()
        }
    }
}

// MARK: - Contacts Screen (Standalone - with its own NavigationStack)
/// Use this when ContactsScreen is the root of navigation (e.g., if it had its own tab)
struct ContactsScreenView: View {
    @StateObject private var viewModel = OrganizeContactViewModel(contactStore: CNContactStore())
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            OrganizeContactsView(
                viewModel: viewModel,
                onDuplicatesTapped: { path.append(ContactsDestination.duplicates) },
                onIncompleteTapped: { path.append(ContactsDestination.incomplete) },
                onBackupTapped: { path.append(ContactsDestination.backup) },
                onAllContactsTapped: { path.append(ContactsDestination.allContacts) }
            )
            .navigationDestination(for: ContactsDestination.self) { destination in
                contactsDestinationView(for: destination)
            }
        }
        .task {
            await viewModel.getData()
        }
    }
    
    @ViewBuilder
    private func contactsDestinationView(for destination: ContactsDestination) -> some View {
        switch destination {
        case .duplicates:
            DuplicateContactsViewDesign(
                viewModel: DuplicateContactsViewModel(contactStore: CNContactStore())
            )
        case .incomplete:
            IncompleteContactView(
                viewModel: IncompleteContactViewModel(contactStore: CNContactStore())
            )
        case .allContacts:
            AllContactsView(
                viewModel: AllContactsVIewModel(contactStore: CNContactStore())
            )
        case .backup:
            ContactsBackupView(contacts: viewModel.allContacts)
        }
    }
}

// MARK: - Contacts Navigation Destinations
enum ContactsDestination: Hashable {
    case duplicates
    case incomplete
    case allContacts
    case backup
}

// MARK: - Contacts Backup View
struct ContactsBackupView: View {
    let contacts: [CNContact]
    @State private var showShareSheet = false
    @State private var vCardURL: URL?
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.teal, .teal.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .teal.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(spacing: 8) {
                    Text("Backup Contacts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Export \(contacts.count) contacts as vCard (.vcf) file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Export Button
                Button(action: exportContacts) {
                    HStack(spacing: 12) {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                        Text(isExporting ? "Exporting..." : "Export as vCard")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.teal, .teal.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isExporting || contacts.isEmpty)
                .padding(.horizontal, 24)
                
                // Info cards
                VStack(spacing: 12) {
                    BackupInfoCard(
                        icon: "checkmark.shield.fill",
                        title: "Safe & Secure",
                        description: "Your contacts are exported locally to your device"
                    )
                    
                    BackupInfoCard(
                        icon: "icloud.fill",
                        title: "Share Anywhere",
                        description: "Save to iCloud, email, or any other app"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = vCardURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func exportContacts() {
        isExporting = true
        
        Task {
            do {
                let url = try await createVCardFile()
                await MainActor.run {
                    vCardURL = url
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                }
                print("Error exporting contacts: \(error)")
            }
        }
    }
    
    private func createVCardFile() async throws -> URL {
        let contactStore = CNContactStore()
        let keysToFetch = [CNContactVCardSerialization.descriptorForRequiredKeys()]
        
        var fullContacts: [CNContact] = []
        for contact in contacts {
            if let fullContact = try? contactStore.unifiedContact(
                withIdentifier: contact.identifier,
                keysToFetch: keysToFetch
            ) {
                fullContacts.append(fullContact)
            }
        }
        
        let vCardData = try CNContactVCardSerialization.data(with: fullContacts)
        
        let fileName = "Contacts_Backup_\(Date().formatted(.dateTime.year().month().day())).vcf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try vCardData.write(to: tempURL)
        
        return tempURL
    }
}

// MARK: - Backup Info Card
struct BackupInfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.teal)
                .frame(width: 44, height: 44)
                .background(Color.teal.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
