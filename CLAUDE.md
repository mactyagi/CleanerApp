# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app
xcodebuild -project CleanerApp.xcodeproj -scheme CleanerApp -configuration Debug build

# Build for release
xcodebuild -project CleanerApp.xcodeproj -scheme CleanerApp -configuration Release build

# Clean build
xcodebuild -project CleanerApp.xcodeproj -scheme CleanerApp clean
```

Note: This project has no test target configured.

## Architecture (UPDATED: SwiftUI Only)

**iOS app using MVVM + SwiftUI + Combine** - Pure SwiftUI, no UIKit.

**Minimum iOS Version: iOS 16+** (NavigationStack requirement)

### App Structure
```
@main App (CleanerApp.swift)
  ├── LaunchView (animated splash)
  └── ContentView (TabView with NavigationStack per tab)
      ├── HomeTabView → HomeView
      ├── VideoCompressorTabView → VideoCompressorView
      └── SettingsTabView → SettingView
```

### Tab Structure
- **Home Tab** (`HomeView` + `HomeViewModel`): Device cleaning hub
  - HomeView: Dashboard with device stats, storage progress, navigation cards
  - MediaHubView: Media categories (Similar, Duplicate, Screenshots, Videos)
  - CalendarView: Calendar/Reminders with EventKit
  - ContactsHubView: Contact organization hub
  - 6 photo/video screens using generic MediaGridView component

- **Compressor Tab** (`VideoCompressorView`): Video compression
  - VideoCompressorView: Video grid with thumbnails
  - CompressQualityView: 3-state compression UI (before/during/after)

- **Settings Tab** (`SettingView` - SwiftUI): App settings and feature voting

### Key Directories
```
CleanerApp/
├── App/                    # Entry point, ContentView, State management
│   ├── CleanerApp.swift   # @main app with UIApplicationDelegateAdaptor
│   ├── ContentView.swift  # Root TabView structure
│   └── State/             # AppState, AppearanceManager
│
├── Core/
│   ├── Components/        # Reusable SwiftUI components
│   │   ├── MediaGridView.swift (MOST IMPORTANT - generic grid)
│   │   ├── CircularProgressView.swift
│   │   └── CommonComponents.swift (EmptyStateView, etc.)
│   ├── Extensions/        # Int64, PHAsset, TimeInterval helpers
│   └── Utilities/         # PreviewProvider, DeletionHandlers
│
├── Tabs/
│   ├── Home/
│   │   ├── ViewModels/
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── MediaHubViewModel.swift
│   │   │   └── CalendarViewModel.swift
│   │   └── Views/
│   │       ├── HomeView.swift
│   │       ├── Media/
│   │       ├── Calendar/
│   │       └── Contacts/
│   ├── VideoCompressor/
│   │   ├── ViewModels/
│   │   │   ├── VideoCompressorViewModel.swift
│   │   │   └── CompressQualityViewModel.swift
│   │   └── Views/
│   │       ├── VideoCompressorView.swift
│   │       └── CompressQualityView.swift
│   ├── Settings/ (existing)
│   └── Launch/
│       └── LaunchView.swift
│
├── Resources/             # AppDelegate (slim), Core Data, Assets
└── Helper/                # Existing managers (CoreDataManager, GalleryManager, etc.)
```

### State Management (3 Levels)
1. **App-level** (AppState) - Permissions, global alerts, tab selection
2. **Tab-level** (NavigationStack) - Per-tab navigation paths via NavigationDestination
3. **Screen-level** (ViewModels) - Screen-specific data with @Published properties

### Data Layer
- **Core Data**: `DBAsset` entity for photo/video metadata
  - Used directly in MediaGridView (DBAsset conforms to MediaGridItem protocol)
  - CoreDataManager for CRUD operations

- **Firebase Firestore**: Feature requests and voting (unchanged)

- **Photos Framework**: Photo library access via PHAsset
  - Async/await wrappers in Extensions.swift
  - Efficient thumbnail loading with PHImageManager

- **EventKit**: Calendar/Reminder operations via EKEventStore

- **Contacts**: Contact management via CNContactStore

### Key Components

#### MediaGridView (Generic Grid Component) 🎯
**Most important reusable component** - Replaces 386-line BaseViewController
- Powers 6 screens with 90% code reuse:
  - SimilarPhotosView
  - DuplicatePhotosView
  - ScreenshotsView
  - AllVideosView
  - ScreenRecordingsView
  - OtherPhotosView
- Features:
  - Generic with `MediaGridItem` protocol constraint
  - Multi-selection with `Set<String>`
  - Per-section "Select All" buttons
  - Context menu for previews
  - LazyVGrid 2-column layout
  - Batch deletion with progress

#### Managers (Existing, Slim Integration)
| Manager | Purpose |
|---------|---------|
| `CoreDataManager` | Core Data CRUD (singleton) |
| `CoreDataPHAssetManager` | Photo library scanning, duplicate detection |
| `FireStoreManager` | Firestore for feature requests |
| `DeviceInfoManager` | Device stats (RAM, storage, CPU) |
| `GalleryManager` | Photo/video asset operations |

All managers work unchanged with the new SwiftUI UI layer.

### Duplicate Detection
Uses Vision framework + SHA256 hashing (unchanged from UIKit version):
- Similar photos detected via `VNFeaturePrintObservation`
- Configurable distance threshold
- Runs in background via CoreDataPHAssetManager

## Dependencies (Swift Package Manager)
- `firebase-ios-sdk` - Analytics, Firestore, Crashlytics (unchanged)
- `AlertToast` - Toast notifications (unchanged)

## Firebase Integration
- Configuration in `GoogleService-Info.plist` (unchanged)
- Analytics events defined in `EventsHandler.swift` (unchanged)
- Error logging via `logEvent()` / `logError()` functions (unchanged)
- Slim AppDelegate keeps Firebase init

## SwiftUI Patterns Used

### Navigation
- `NavigationStack` per tab (iOS 16+)
- `NavigationDestination` enum for typed navigation
- Programmatic navigation via `NavigationPath`
- Tab selection via `@EnvironmentObject AppState`

### State Management
- `@StateObject` for ViewModel ownership
- `@ObservedObject` for child views
- `@Published` for reactive data
- `@EnvironmentObject` for global state

### Async/Await
- Modern concurrency throughout
- PHAsset image loading with `withCheckedContinuation`
- EventKit with `async/await`
- Task cancellation for cleanup

### Styling
- Asset Catalog colors (Color.blue, Color.secondary)
- SwiftUI modifiers (.cornerRadius, .padding, etc.)
- Preview support with #Preview macro

## Recent Changes (Migration)

**✅ Completed: Full UIKit → SwiftUI Migration**
- Removed: All storyboards and XIBs planned for deletion
- Removed: UIKit ViewControllers planned for deletion
- Added: 40+ new SwiftUI files (views, viewmodels, components)
- Updated: AppDelegate (slim down, keep Firebase)
- New: App entry point (CleanerApp.swift with @main)

See `MIGRATION_SUMMARY.md` for detailed migration notes.
