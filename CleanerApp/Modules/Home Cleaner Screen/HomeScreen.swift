//
//  HomeScreen.swift
//  CleanerApp
//
//  Final SwiftUI Home Screen Implementation
//

import SwiftUI
import Contacts
import EventKit
import Photos

// MARK: - Home Tab View (Navigation Container)
struct HomeNavigationView: View {
    @State var path: NavigationPath = NavigationPath()
    @StateObject private var contactsViewModel = OrganizeContactViewModel(contactStore: CNContactStore())
    @StateObject private var mediaViewModel = MediaViewModel()
    @StateObject private var homeViewModel = HomeScreenViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            HomeScreen(viewModel: homeViewModel, path: $path)
            .navigationDestination(for: HomeDestination.self) { destination in
                homeDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(for: ContactsDestination.self) { destination in
                contactsDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(for: MediaDestination.self) { destination in
                mediaDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
                
            }
        }
    }
    
    @ViewBuilder
    private func homeDestinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .media:
            MediaFlowView(viewModel: mediaViewModel, path: $path)
        case .contacts:
            OrganizeContactsView(viewModel: contactsViewModel, path: $path)
        case .calendar:
            CalendarDesignSelector()
        case .compress:
            CompressorDetailView()
        case .deviceHealth(let tab):
            DeviceHealthView(initialTab: tab, homeViewModel: homeViewModel, path: $path)
        case .speedTest:
            SpeedTestView()
        case .storageDetail:
            StorageDetailView(homeViewModel: homeViewModel, path: $path)
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
            ContactsBackupView(contacts: contactsViewModel.allContacts)
        }
    }
    
    @ViewBuilder
    private func mediaDestinationView(for destination: MediaDestination) -> some View {
        switch destination {
        case .baseView(let cellType):
            if let predicate = mediaViewModel.getPredicate(mediaType: cellType) {
                BaseViewSwiftUI(
                    predicate: predicate,
                    groupType: cellType.groupType,
                    type: cellType
                )
            } else {
                Text("No data available")
            }
        case .otherPhotos(let cellType):
            OtherPhotosSwiftUI(
                predicate: mediaViewModel.getPredicate(mediaType: cellType),
                cellType: cellType
            )
        }
    }
}

// MARK: - Device Health Tab
enum DeviceHealthTab: String, CaseIterable, Hashable {
    case cpu = "CPU"
    case ram = "RAM"
    case network = "Network"

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .ram: return "memorychip"
        case .network: return "wifi"
        }
    }

    var color: Color {
        switch self {
        case .cpu: return .purple
        case .ram: return .indigo
        case .network: return .teal
        }
    }
}

// MARK: - Home Destinations
enum HomeDestination: Hashable {
    case media
    case contacts
    case calendar
    case compress
    case deviceHealth(DeviceHealthTab)
    case speedTest
    case storageDetail
}

// MARK: - Home Screen View
struct HomeScreen: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    @Binding var path: NavigationPath
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Storage Section (Design 4 Style)
                Button {
                    path.append(HomeDestination.storageDetail)
                } label: {
                    storageCard
                }
                .buttonStyle(.plain)

                // Device Info Row
                deviceInfoRow

                // Calendar & Contacts Row
                HStack(spacing: 12) {
                    calendarCard
                    contactsCard
                }

                // Photos Card
                photosCard

                // Compress Card
                compressCard

                // Quick Tips Section
                quickTipsCard
            }
            .padding()
        }
        .background(Color.lightBlueDarkGrey)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .alert("Access Needed", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(permissionAlertMessage)
        }
        .onAppear {
            viewModel.updateData()
            viewModel.startDeviceInfoTimer()
        }
        .onDisappear {
            viewModel.stopDeviceInfoTimer()
        }
    }

    // MARK: - Storage Card (Design 4 Style with Design 1 Colors)
    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Storage")
                .font(.headline)

            HStack(alignment: .bottom) {
                Text(viewModel.usedStorage.formatBytes())
                    .font(.system(size: 32, weight: .bold))
                Text("/ \(viewModel.totalStorage.formatBytes())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            // Segmented storage bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: max(0, geo.size.width * viewModel.appsProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: max(0, geo.size.width * viewModel.photosProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: max(0, geo.size.width * viewModel.otherProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(height: 12)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .blue, label: "Apps")
                legendItem(color: .green, label: "Photos")
                legendItem(color: .orange, label: "Other")
                legendItem(color: .gray.opacity(0.3), label: "Free")
            }
            .font(.caption)
        }
        .padding()
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(16)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Device Info Row
    private var deviceInfoRow: some View {
        HStack(spacing: 12) {
            Button {
                path.append(HomeDestination.deviceHealth(.cpu))
            } label: {
                deviceInfoCard(
                    icon: "cpu",
                    title: "CPU",
                    value: "\(viewModel.cpuUsage)%",
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            Button {
                path.append(HomeDestination.deviceHealth(.ram))
            } label: {
                deviceInfoCard(
                    icon: "memorychip",
                    title: "RAM",
                    value: viewModel.usedRAM.formatBytes(),
                    color: .indigo
                )
            }
            .buttonStyle(.plain)

            Button {
                path.append(HomeDestination.deviceHealth(.network))
            } label: {
                deviceInfoCard(
                    icon: "wifi",
                    title: "Network",
                    value: "Active",
                    color: .teal
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func deviceInfoCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(12)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        Button(action: {
            path.append(HomeDestination.calendar)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 35, height: 35)
                        Image(systemName: "calendar")
                            .foregroundColor(.pink)
                    }
                    Text("Calendar")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack {
                    if let count = viewModel.eventsCount {
                        Text("Events: \(count)")
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contacts Card
    private var contactsCard: some View {
        Button(action: {
            requestContactsAccess()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 35, height: 35)
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                    }
                    Text("Contacts")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack {
                    if let count = viewModel.contactsCount {
                        Text("Contacts: \(count)")
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photos Card
    private var photosCard: some View {
        Button(action: {
            if viewModel.photosAndVideosSize != nil {
                path.append(HomeDestination.media)
            } else {
                permissionAlertMessage = "Allow the app access to Photos. No files will be deleted without your permission."
                showPermissionAlert = true
            }
        }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 45, height: 45)
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Photos & Videos")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Items: \(viewModel.photosAndVideosCount)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack {
                    if let size = viewModel.photosAndVideosSize {
                        Text(size.formatBytes())
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 80)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compress Card
    private var compressCard: some View {
        Button(action: {
            path.append(HomeDestination.compress)
        }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 45, height: 45)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Compressor")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Reduce video file sizes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack {
                    Text("Compress")
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 80)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Tips Card
    private var quickTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tips")
                .font(.headline)

            VStack(spacing: 10) {
                tipRow(icon: "trash", text: "Delete duplicate photos to free up space", color: .red)
                tipRow(icon: "person.2.slash", text: "Merge duplicate contacts", color: .orange)
                tipRow(icon: "calendar.badge.minus", text: "Remove old calendar events", color: .pink)
                tipRow(icon: "video.badge.checkmark", text: "Compress large videos", color: .blue)
            }
        }
        .padding()
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(15)
    }

    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Helper Methods
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    path.append(HomeDestination.contacts)
                } else {
                    permissionAlertMessage = "In order to find duplicate and empty contacts, the app needs access to contacts."
                    showPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HomeScreen(viewModel: HomeScreenViewModel(), path: .constant(NavigationPath()))
    }
}
