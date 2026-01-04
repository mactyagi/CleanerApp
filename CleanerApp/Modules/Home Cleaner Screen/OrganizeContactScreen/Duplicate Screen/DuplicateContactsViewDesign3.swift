//
//  DuplicateContactsViewDesign3.swift
//  CleanerApp
//
//  Design 3: Modern Gradient Accent Design
//  - Gradient header cards
//  - Floating action button for merge
//  - Contact photos/avatars with gradient border
//  - Pill-shaped selection indicators
//

import SwiftUI
import Contacts
import ContactsUI

// MARK: - Design 3: Modern Gradient Design
struct DuplicateContactsViewDesign3: View {
    @ObservedObject var viewModel: DuplicateContactsViewModel
    @State private var showMergeAlert = false
    @State private var selectedIndex: Int?
    @State private var selectedContact: CNContact?
    @State private var showContactDetail = false

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 20) {
                    // Stats header
                    Design3StatsHeader(
                        totalGroups: viewModel.dataSource.count,
                        totalContacts: viewModel.dataSource.reduce(0) { $0 + $1.duplicatesContacts.count }
                    )
                    .padding(.horizontal)

                    ForEach(Array(viewModel.dataSource.enumerated()), id: \.offset) { index, tuple in
                        Design3GroupCard(
                            tuple: tuple,
                            index: index,
                            onSelectionChange: { viewIndex, isSelected in
                                viewModel.dataSource[index].duplicatesContacts[viewIndex].isSelected = isSelected
                                viewModel.resetMergeContactAt(indexes: [index])
                            },
                            onSelectAll: { isAllSelected in
                                viewModel.resetSelectionAt(index: index, isSelectedAll: isAllSelected)
                            },
                            onMerge: {
                                selectedIndex = index
                                showMergeAlert = true
                            },
                            onContactTap: { contact in
                                selectedContact = contact
                                showContactDetail = true
                            }
                        )
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Duplicates")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Merge Contacts?", isPresented: $showMergeAlert, titleVisibility: .visible) {
            Button("Merge Selected", role: .destructive) {
                if let index = selectedIndex {
                    logEvent(Event.DuplicateContactScreen.mergeConfirmed.rawValue, parameter: ["merge_count": viewModel.dataSource[index].duplicatesContacts.count])
                    viewModel.mergeAndSaveAt(indexPath: IndexPath(row: index, section: 0))
                }
            }
            Button("Cancel", role: .cancel) {
                logEvent(Event.DuplicateContactScreen.mergeCancel.rawValue, parameter: nil)
            }
        } message: {
            Text("Selected contacts will be merged into one.")
        }
        .sheet(isPresented: $showContactDetail) {
            if let contact = selectedContact {
                ContactDetailViewDesign3(contact: contact)
            }
        }
        .onAppear {
            logEvent(Event.DuplicateContactScreen.appear.rawValue, parameter: nil)
        }
        .onDisappear {
            logEvent(Event.DuplicateContactScreen.disappear.rawValue, parameter: nil)
        }
    }
}

// MARK: - Stats Header
struct Design3StatsHeader: View {
    let totalGroups: Int
    let totalContacts: Int

    var body: some View {
        HStack(spacing: 16) {
            Design3StatPill(
                icon: "person.2.fill",
                value: "\(totalGroups)",
                label: "Groups"
            )

            Design3StatPill(
                icon: "person.fill",
                value: "\(totalContacts)",
                label: "Contacts"
            )
        }
    }
}

struct Design3StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(Color(uiColor: .label))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Group Card
struct Design3GroupCard: View {
    let tuple: duplicateAndMergedContactTuple
    let index: Int
    let onSelectionChange: (Int, Bool) -> Void
    let onSelectAll: (Bool) -> Void
    let onMerge: () -> Void
    let onContactTap: (CNContact) -> Void

    private var selectedCount: Int {
        tuple.duplicatesContacts.filter { $0.isSelected }.count
    }

    private var canMerge: Bool {
        selectedCount > 1
    }

    private var isAllSelected: Bool {
        tuple.duplicatesContacts.allSatisfy { $0.isSelected }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Group \(index + 1)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(tuple.duplicatesContacts.count) contacts found")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Select all toggle
                Button(action: { onSelectAll(!isAllSelected) }) {
                    Text(isAllSelected ? "Deselect" : "Select All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(uiColor: .darkBlue))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white)
                        .cornerRadius(20)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Merged preview
            if let mergedContact = tuple.mergedContact {
                Design3MergedPreview(contact: mergedContact) {
                    onContactTap(mergedContact)
                }
            }

            // Contact list
            VStack(spacing: 0) {
                ForEach(Array(tuple.duplicatesContacts.enumerated()), id: \.offset) { viewIndex, customContact in
                    Design3ContactRow(
                        contact: customContact.contact,
                        isSelected: customContact.isSelected,
                        isLast: viewIndex == tuple.duplicatesContacts.count - 1,
                        onToggle: {
                            onSelectionChange(viewIndex, !customContact.isSelected)
                        },
                        onTap: {
                            onContactTap(customContact.contact)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Merge button
            Button(action: onMerge) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.merge")
                    Text("Merge \(selectedCount) Contacts")
                        .fontWeight(.semibold)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    canMerge ?
                    LinearGradient(
                        colors: [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!canMerge)
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Merged Preview
struct Design3MergedPreview: View {
    let contact: CNContact
    let onTap: () -> Void

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with gradient border
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                    Image(systemName: "person.crop.circle.badge.checkmark.fill")
                        .font(.title3)
                        .foregroundColor(Color(uiColor: .darkBlue))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MERGED RESULT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(uiColor: .darkBlue))
                        .tracking(0.5)

                    Text(fullName.isEmpty ? "No Name" : fullName)
                        .font(.body)
                        .foregroundColor(Color(uiColor: .label))

                    Text("\(contact.phoneNumbers.count) phone, \(contact.emailAddresses.count) email")
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(12)
            .background(Color(uiColor: .lightBlueDarkGrey).opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Contact Row
struct Design3ContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let isLast: Bool
    let onToggle: () -> Void
    let onTap: () -> Void

    private var initials: String {
        let first = contact.givenName.first.map(String.init) ?? ""
        let last = contact.familyName.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var phoneNumber: String {
        contact.phoneNumbers.first?.value.stringValue ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color(uiColor: .secondaryLabel))
                }
                .frame(width: 44, height: 44)
                .onTapGesture {
                    vibrate()
                    onToggle()
                }

                // Info
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fullName.isEmpty ? "No Name" : fullName)
                            .font(.body)
                            .foregroundColor(Color(uiColor: .label))

                        if !phoneNumber.isEmpty {
                            Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Selection pill
                Button(action: {
                    vibrate()
                    onToggle()
                }) {
                    Text(isSelected ? "Selected" : "Select")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : Color(uiColor: .darkBlue))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ?
                            Color(uiColor: .darkBlue) :
                            Color(uiColor: .darkBlue).opacity(0.1)
                        )
                        .cornerRadius(20)
                }
            }
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

// MARK: - Contact Detail View
struct ContactDetailViewDesign3: UIViewControllerRepresentable {
    let contact: CNContact
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.allowsActions = false
        contactVC.delegate = context.coordinator

        let navController = UINavigationController(rootViewController: contactVC)
        contactVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissView)
        )

        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var parent: ContactDetailViewDesign3

        init(_ parent: ContactDetailViewDesign3) {
            self.parent = parent
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.dismiss()
        }

        @objc func dismissView() {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview("Design 3 - Modern Gradient") {
    NavigationView {
        DuplicateContactsViewDesign3(viewModel: DuplicateContactsViewModel(contactStore: CNContactStore()))
    }
}
