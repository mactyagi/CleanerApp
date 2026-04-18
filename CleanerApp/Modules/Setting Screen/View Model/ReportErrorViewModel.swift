import SwiftUI
import Foundation
import Combine
import PhotosUI

class ReportErrorViewModel: ObservableObject {
    let minTitleLength: Int = 4
    let maxTitleLength: Int = 80
    let minDescriptionLength: Int = 10
    let maxDescriptionLength: Int = 500
    let maxAttachments: Int = 3

    @Published var title: String = "" {
        didSet {
            if title.count > maxTitleLength { title = String(title.prefix(maxTitleLength)) }
            validate()
        }
    }
    @Published var description: String = "" {
        didSet {
            if description.count > maxDescriptionLength { description = String(description.prefix(maxDescriptionLength)) }
            validate()
        }
    }
    @Published var category: ErrorCategory = .crash
    @Published var area: ErrorArea = .other

    @Published var selectedPhotosItems: [PhotosPickerItem] = [] {
        didSet { loadImages() }
    }
    @Published var attachments: [UIImage] = []

    @Published var isLoading: Bool = false
    @Published var showCompletionAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var isFormValid: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupValidation()
    }

    private func setupValidation() {
        Publishers.CombineLatest($title, $description)
            .map { [weak self] title, description in
                guard let self else { return false }
                return title.trimmingCharacters(in: .whitespacesAndNewlines).count >= self.minTitleLength &&
                title.count <= self.maxTitleLength &&
                description.trimmingCharacters(in: .whitespacesAndNewlines).count >= self.minDescriptionLength &&
                description.count <= self.maxDescriptionLength
            }
            .assign(to: \.isFormValidBacking, on: self)
            .store(in: &cancellables)
    }

    private var isFormValidBacking: Bool = false {
        didSet { isFormValid = isFormValidBacking }
    }

    private func validate() {
        isFormValidBacking = title.trimmingCharacters(in: .whitespacesAndNewlines).count >= minTitleLength &&
        title.count <= maxTitleLength &&
        description.trimmingCharacters(in: .whitespacesAndNewlines).count >= minDescriptionLength &&
        description.count <= maxDescriptionLength
    }

    func submitReport(completion: @escaping () -> Void) {
        isLoading = true

        let now = Date()
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let base64Images = compressAndEncodeImages()

        let report = ErrorReport(
            category: category,
            area: area,
            errorTitle: title.trimmingCharacters(in: .whitespacesAndNewlines),
            errorDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceModel: device.model,
            iosVersion: device.systemVersion,
            appVersion: appVersion,
            screenshots: base64Images,
            reportedAt: ISO8601DateFormatter.cached.string(from: now),
            reportedBy: UIDevice.deviceId
        )

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                self.showCompletionAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { completion() }
            }
            return
        }

        FireStoreManager().addErrorReport(errorReport: report) { [weak self] success in
            guard let self else { return }
            self.isLoading = false
            if success {
                self.showCompletionAlert = true
            } else {
                self.showErrorAlert = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { completion() }
        }
    }

    private func compressAndEncodeImages() -> [String] {
        attachments.compactMap { image in
            let maxDimension: CGFloat = 400
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            guard let data = resized?.jpegData(compressionQuality: 0.4) else { return nil }
            return data.base64EncodedString()
        }
    }

    func resetAlerts() {
        showCompletionAlert = false
        showErrorAlert = false
    }

    func removeAttachment(at index: Int) {
        guard index < attachments.count else { return }
        attachments.remove(at: index)
        if index < selectedPhotosItems.count {
            selectedPhotosItems.remove(at: index)
        }
    }

    private func loadImages() {
        let items = selectedPhotosItems.prefix(maxAttachments)
        var loaded: [UIImage] = []
        let group = DispatchGroup()

        for item in items {
            group.enter()
            item.loadTransferable(type: Data.self) { result in
                defer { group.leave() }
                if case .success(let data) = result, let data, let image = UIImage(data: data) {
                    loaded.append(image)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.attachments = loaded
        }
    }
}
