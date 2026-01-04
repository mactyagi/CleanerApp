//
//  DuplicateContactsViewDesign1.swift
//  CleanerApp
//
//  Design 1: Card-based layout with rounded corners
//  - Clean card design with grouped contacts
//  - Merged contact preview at top of each card
//  - Checkbox selection on right side
//

import SwiftUI
import Contacts
import ContactsUI

// MARK: - Design 1: Card-Based Layout
struct DuplicateContactsViewDesign1: View {
    @ObservedObject var viewModel: DuplicateContactsViewModel
    @State private var showMergeAlert = false
    @State private var selectedIndexPath: IndexPath?
    @State private var selectedContact: CNContact?
    @State private var showContactDetail = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.dataSource.enumerated()), id: \.offset) { index, tuple in
                    DuplicateGroupView(
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
                            selectedIndexPath = IndexPath(row: index, section: 0)
                            showMergeAlert = true
                        },
                        onContactTap: { contact in
                            selectedContact = contact
                            showContactDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alert!", isPresented: $showMergeAlert) {
            Button("Merge", role: .destructive) {
                if let indexPath = selectedIndexPath {
                    logEvent(Event.DuplicateContactScreen.mergeConfirmed.rawValue, parameter: ["merge_count": viewModel.dataSource[indexPath.row].duplicatesContacts.count])
                    viewModel.mergeAndSaveAt(indexPath: indexPath)
                }
            }
            Button("Cancel", role: .cancel) {
                logEvent(Event.DuplicateContactScreen.mergeCancel.rawValue, parameter: nil)
            }
        } message: {
            Text("Are you sure want to merge?")
        }
        .sheet(isPresented: $showContactDetail) {
            if let contact = selectedContact {
                ContactDetailView(contact: contact)
            }
        }
        .onAppear {
            logEvent(Event.DuplicateContactScreen.appear.rawValue, parameter: nil)
            logEvent(Event.DuplicateContactScreen.totalMergeItems.rawValue, parameter: ["count": viewModel.dataSource.count])
        }
        .onDisappear {
            logEvent(Event.DuplicateContactScreen.disappear.rawValue, parameter: nil)
        }
    }
}

// MARK: - Duplicate Group View
struct DuplicateGroupView: View {
    let tuple: duplicateAndMergedContactTuple
    let index: Int
    let onSelectionChange: (Int, Bool) -> Void
    let onSelectAll: (Bool) -> Void
    let onMerge: () -> Void
    let onContactTap: (CNContact) -> Void

    @State private var isAllSelected: Bool = true

    private var selectedCount: Int {
        tuple.duplicatesContacts.filter { $0.isSelected }.count
    }

    private var shouldEnableMerge: Bool {
        selectedCount > 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with duplicate count
            HStack {
                Text("Duplicate Count: \(tuple.duplicatesContacts.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(uiColor: .darkGray))

                Spacer()

                Button(action: {
                    isAllSelected.toggle()
                    onSelectAll(isAllSelected)
                }) {
                    Text(isAllSelected ? ConstantString.deSelectAll.rawValue : ConstantString.selectAll.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .darkBlue))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Merged contact preview
            if let mergedContact = tuple.mergedContact {
                MergedContactView(contact: mergedContact, onTap: {
                    onContactTap(mergedContact)
                })
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Duplicate contacts list
            VStack(spacing: 8) {
                ForEach(Array(tuple.duplicatesContacts.enumerated()), id: \.offset) { viewIndex, customContact in
                    ContactRowView(
                        contact: customContact.contact,
                        isSelected: customContact.isSelected,
                        onSelectionChange: { isSelected in
                            onSelectionChange(viewIndex, isSelected)
                            updateAllSelectedState()
                        },
                        onContactTap: {
                            onContactTap(customContact.contact)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)

            // Merge button
            Button(action: onMerge) {
                Text("Merge")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(shouldEnableMerge ? Color(uiColor: .darkBlue) : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!shouldEnableMerge)
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .onAppear {
            updateAllSelectedState()
        }
    }

    private func updateAllSelectedState() {
        isAllSelected = tuple.duplicatesContacts.allSatisfy { $0.isSelected }
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: CNContact
    let isSelected: Bool
    let onSelectionChange: (Bool) -> Void
    let onContactTap: () -> Void

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var phoneNumbers: String {
        contact.phoneNumbers.map { $0.value.stringValue }.joined(separator: " • ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Contact info
            Button(action: onContactTap) {
                VStack(alignment: .leading, spacing: 4) {
                    if !fullName.isEmpty {
                        Text(fullName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(uiColor: .label))
                    }

                    if !phoneNumbers.isEmpty {
                        Text(phoneNumbers)
                            .font(.caption)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Selection checkbox
            Button(action: {
                vibrate()
                onSelectionChange(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        isSelected ? Color.white : Color(uiColor: .darkGray),
                        Color(uiColor: .darkBlue)
                    )
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Merged Contact View
struct MergedContactView: View {
    let contact: CNContact
    let onTap: () -> Void

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var phoneNumbers: String {
        contact.phoneNumbers.map { $0.value.stringValue }.joined(separator: " • ")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Merged Contact Preview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkBlue))

                if !fullName.isEmpty {
                    Text(fullName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color(uiColor: .label))
                }

                if !phoneNumbers.isEmpty {
                    Text(phoneNumbers)
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(uiColor: .lightBlueDarkGrey))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Detail View (UIKit Wrapper)
struct ContactDetailView: UIViewControllerRepresentable {
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
            action: #selector(Coordinator.dismiss)
        )

        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var parent: ContactDetailView

        init(_ parent: ContactDetailView) {
            self.parent = parent
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.dismiss()
        }

        @objc func dismiss() {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview("Design 1 - Card Based") {
    NavigationView {
        DuplicateContactsViewDesign1(viewModel: DuplicateContactsViewModel(contactStore: CNContactStore()))
    }
}
