//
//  AppState.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import Foundation
import Combine
import Photos
import Contacts
import EventKit

@MainActor
class AppState: ObservableObject {
    // Tab selection
    @Published var selectedTab: TabSelection = .home

    // Deep linking/navigation state
    @Published var navigationPath: [NavigationDestination] = []

    // Global alerts/toasts
    @Published var showAlert: Bool = false
    @Published var alertConfig: AlertConfig?

    // Permissions state (app-wide)
    @Published var photoLibraryAuthorized: Bool = false
    @Published var contactsAuthorized: Bool = false
    @Published var calendarAuthorized: Bool = false

    // Background processing state
    @Published var isProcessingPhotos: Bool = false
    @Published var processingProgress: Float = 0.0

    init() {
        checkPermissions()
    }

    // MARK: - Permission Checking

    private func checkPermissions() {
        Task {
            await checkPhotoLibraryPermission()
            await checkContactsPermission()
            await checkCalendarPermission()
        }
    }

    private func checkPhotoLibraryPermission() async {
        if #available(iOS 14, *) {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            photoLibraryAuthorized = (status == .authorized)
        }
    }

    private func checkContactsPermission() async {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            contactsAuthorized = true
        }
    }

    private func checkCalendarPermission() async {
        let eventStore = EKEventStore()
        if #available(iOS 17, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                calendarAuthorized = granted
            } catch {
                calendarAuthorized = false
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            calendarAuthorized = (status == .authorized)
        }
    }

    // MARK: - Navigation

    func resetToHome() {
        selectedTab = .home
        navigationPath.removeAll()
    }

    // MARK: - Alert Management

    func showError(_ title: String, _ message: String) {
        alertConfig = AlertConfig(
            title: title,
            message: message,
            primaryButton: AlertButton(title: "OK") { [weak self] in
                self?.showAlert = false
            }
        )
        showAlert = true
    }
}

// MARK: - Types

enum TabSelection: Hashable {
    case home
    case compressor
    case settings
}

enum NavigationDestination: Hashable {
    case media
    case similarPhotos
    case duplicatePhotos
    case screenshots
    case allVideos
    case screenRecordings
    case otherPhotos
    case calendar
    case contacts
    case duplicateContacts
    case allContacts
    case incompleteContacts
    case videoQualitySelection(videoId: String)
    case imagePreview(assetIds: [String], selectedIndex: Int)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .media:
            hasher.combine("media")
        case .similarPhotos:
            hasher.combine("similarPhotos")
        case .duplicatePhotos:
            hasher.combine("duplicatePhotos")
        case .screenshots:
            hasher.combine("screenshots")
        case .allVideos:
            hasher.combine("allVideos")
        case .screenRecordings:
            hasher.combine("screenRecordings")
        case .otherPhotos:
            hasher.combine("otherPhotos")
        case .calendar:
            hasher.combine("calendar")
        case .contacts:
            hasher.combine("contacts")
        case .duplicateContacts:
            hasher.combine("duplicateContacts")
        case .allContacts:
            hasher.combine("allContacts")
        case .incompleteContacts:
            hasher.combine("incompleteContacts")
        case .videoQualitySelection(let videoId):
            hasher.combine("videoQuality")
            hasher.combine(videoId)
        case .imagePreview(let assetIds, let index):
            hasher.combine("imagePreview")
            hasher.combine(assetIds)
            hasher.combine(index)
        }
    }

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?

    init(title: String, message: String, primaryButton: AlertButton, secondaryButton: AlertButton? = nil) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

struct AlertButton {
    let title: String
    let action: () -> Void
}
