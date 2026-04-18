import SwiftUI
import AlertToast
import PhotosUI

struct ReportErrorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReportErrorViewModel()
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        ZStack {
            Color(uiColor: .secondaryBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    instructionCard
                    categoryPicker
                    areaPicker
                    titleInput
                    descriptionInput
                    attachmentsSection
                    deviceInfoCard
                    Spacer(minLength: 0)
                }
                .padding()
            }

            if viewModel.isLoading {
                ZStack {
                    Color(uiColor: .veryLightBlueAndDarkGray).opacity(0.7)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(uiColor: .darkBlue))
                }
            }
        }
        .navigationTitle("Report an Error")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Submit") {
                    hideKeyboard()
                    viewModel.submitReport { dismiss() }
                }
                .font(.headline)
                .foregroundColor(Color(uiColor: .darkBlue))
                .disabled(!viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1.0 : 0.5)
            }
        }
        .toast(isPresenting: $viewModel.showErrorAlert) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Something went wrong")
        } onTap: {
            viewModel.resetAlerts()
        }
        .toast(isPresenting: $viewModel.showCompletionAlert) {
            AlertToast(displayMode: .alert, type: .complete(.darkBlue))
        } onTap: {
            viewModel.resetAlerts()
        }
        .onAppear { isTitleFocused = true }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Report an Error")
                .font(.headline)
                .foregroundColor(Color(uiColor: .darkBlue))

            Text("Describe the issue clearly so we can fix it quickly. We aim to respond within 3 hours.")
                .font(.callout)
                .foregroundColor(Color(uiColor: .darkGray3))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .offWhiteAndGray))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: .systemGray5), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bug Type")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .darkGray3))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ErrorCategory.allCases, id: \.self) { cat in
                        Button {
                            viewModel.category = cat
                        } label: {
                            Text(cat.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(viewModel.category == cat ? .white : .primary)
                                .background(
                                    Capsule()
                                        .fill(viewModel.category == cat ? Color.orange : Color(uiColor: .offWhiteAndGray))
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(viewModel.category == cat ? Color.clear : Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Area Picker

    private var areaPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feature Area")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .darkGray3))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ErrorArea.allCases, id: \.self) { area in
                        Button {
                            viewModel.area = area
                        } label: {
                            Text(area.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(viewModel.area == area ? .white : .primary)
                                .background(
                                    Capsule()
                                        .fill(viewModel.area == area ? Color.blue : Color(uiColor: .offWhiteAndGray))
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(viewModel.area == area ? Color.clear : Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Title Input

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkGray3))
                Spacer()
                Text("\(viewModel.title.count)/\(viewModel.maxTitleLength)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField("Brief summary of the issue", text: $viewModel.title)
                .focused($isTitleFocused)
                .padding(10)
                .font(.body)
                .background(Color.whiteAndGray2)
                .background(in: .buttonBorder)

            if viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).count < viewModel.minTitleLength {
                Text("Title should be at least \(viewModel.minTitleLength) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Description Input

    private var descriptionInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkGray3))
                Spacer()
                Text("\(viewModel.description.count)/\(viewModel.maxDescriptionLength)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.description)
                    .padding(5)
                    .font(.body)
                    .background(Color.clear)
                    .background(in: .buttonBorder)
                    .overlay(
                        Group {
                            if viewModel.description.isEmpty {
                                Text("Steps to reproduce, expected vs actual behavior...")
                                    .font(.body)
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(10)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
            }
            .frame(height: 150)

            if viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).count < viewModel.minDescriptionLength {
                Text("Description should be at least \(viewModel.minDescriptionLength) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Screenshots (optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .darkGray3))
                Spacer()
                Text("\(viewModel.attachments.count)/\(viewModel.maxAttachments)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.attachments.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                viewModel.removeAttachment(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }

                    if viewModel.attachments.count < viewModel.maxAttachments {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotosItems,
                            maxSelectionCount: viewModel.maxAttachments,
                            matching: .images
                        ) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color(uiColor: .darkBlue))
                                Text("Add")
                                    .font(.caption2)
                                    .foregroundStyle(Color(uiColor: .darkGray3))
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .offWhiteAndGray))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                            .foregroundStyle(Color(uiColor: .systemGray4))
                                    )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Device Info

    private var deviceInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Info (auto-filled)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .darkGray3))

            VStack(alignment: .leading, spacing: 6) {
                deviceInfoRow(label: "Device", value: UIDevice.current.model)
                deviceInfoRow(label: "iOS", value: UIDevice.current.systemVersion)
                deviceInfoRow(label: "App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .offWhiteAndGray))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(uiColor: .systemGray5), lineWidth: 0.5)
                    )
            )
        }
    }

    private func deviceInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        ReportErrorView()
    }
}
