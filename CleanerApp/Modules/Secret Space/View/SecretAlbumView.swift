//
//  SecretAlbumView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SecretAlbumView: View {
    @StateObject private var viewModel = SecretAlbumViewModel()
    @State private var showActionSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.secretItems.isEmpty {
                emptyStateView
            } else {
                gridView
            }
        }
        .navigationTitle("Secret Album")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showActionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog("Add to Secret Album", isPresented: $showActionSheet) {
            Button("Take Photo or Video") {
                showCamera = true
            }
            Button("Import from Library") {
                showPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImages: $viewModel.secretItems)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: { image in
                viewModel.addImage(image)
            })
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.teal)
            }

            VStack(spacing: 8) {
                Text("No Secret Photos")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add photos and videos to keep them private")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showActionSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Photos")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.teal)
                .cornerRadius(25)
            }
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(viewModel.secretItems.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minHeight: 120)
                        .clipped()
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeImage(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Photo Picker (PHPicker wrapper)

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.selectionLimit = 0 // Unlimited
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera View (UIImagePickerController wrapper)

struct CameraView: UIViewControllerRepresentable {
    let capturedImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - ViewModel

@MainActor
class SecretAlbumViewModel: ObservableObject {
    @Published var secretItems: [UIImage] = []

    // Note: In a real implementation, these would be stored securely
    // using file encryption or keychain. For now, this is in-memory only.

    func addImage(_ image: UIImage) {
        secretItems.append(image)
    }

    func removeImage(at index: Int) {
        guard index < secretItems.count else { return }
        secretItems.remove(at: index)
    }
}

#Preview {
    NavigationStack {
        SecretAlbumView()
    }
}
