//
//  PhotoServices.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/17/26.
//
//  Comprehensive photo library integration:
//  - PhotoLibraryManager: Authorization and asset management
//  - ThumbnailGenerator: 1280x720 JPEG thumbnail creation
//  - PhotoPickerView: PHPicker wrapper for image selection
//  - FullScreenPhotoViewer: Zoomable image viewer
//  - PhotoPermissionView: Blocking overlay when permission denied
//

import SwiftUI
import Photos
import PhotosUI
import UIKit
import Combine

// MARK: - Photo Library Manager
/// Singleton managing PHPhotoLibrary authorization and photo operations
@MainActor
class PhotoLibraryManager: ObservableObject {
    static let shared = PhotoLibraryManager()

    @Published var authorizationStatus: PHAuthorizationStatus

    private init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Check current authorization status
    func checkAuthorization() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.authorizationStatus = status
        return status
    }

    /// Request photo library authorization
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = status
        return status
    }

    /// Check and request authorization if needed
    func checkAndRequestAuthorization() async -> PHAuthorizationStatus {
        let currentStatus = await checkAuthorization()

        if currentStatus == .notDetermined {
            return await requestAuthorization()
        }

        return currentStatus
    }

    /// Fetch PHAsset by local identifier
    func fetchAsset(localIdentifier: String) -> PHAsset? {
        guard !localIdentifier.isEmpty else { return nil }

        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        return fetchResult.firstObject
    }

    /// Fetch full-size image from PHAsset
    func fetchFullSizeImage(localIdentifier: String) async -> UIImage? {
        guard let asset = fetchAsset(localIdentifier: localIdentifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Open Photos app
    func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Album Management

    static let albumName = "Airplane-ID"

    /// Fetch our app's album if it exists
    func fetchAppAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", Self.albumName)
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )
        return collections.firstObject
    }

    /// Create the Airplane-ID album
    func createAppAlbum() async -> PHAssetCollection? {
        // Check if it already exists
        if let existing = fetchAppAlbum() {
            return existing
        }

        var placeholder: PHObjectPlaceholder?

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
                placeholder = request.placeholderForCreatedAssetCollection
            }

            guard let placeholder = placeholder else { return nil }

            let fetchResult = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [placeholder.localIdentifier],
                options: nil
            )
            return fetchResult.firstObject
        } catch {
            print("Error creating album: \(error)")
            return nil
        }
    }

    /// Get or create the Airplane-ID album
    func getOrCreateAppAlbum() async -> PHAssetCollection? {
        if let existing = fetchAppAlbum() {
            return existing
        }
        return await createAppAlbum()
    }

    /// Add a photo to the Airplane-ID album
    func addPhotoToAppAlbum(localIdentifier: String) async -> Bool {
        guard let asset = fetchAsset(localIdentifier: localIdentifier) else {
            print("Asset not found: \(localIdentifier)")
            return false
        }

        guard let album = await getOrCreateAppAlbum() else {
            print("Could not get or create album")
            return false
        }

        // Check if photo is already in album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", localIdentifier)
        let existingAssets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        if existingAssets.count > 0 {
            // Already in album
            return true
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                guard let addRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                addRequest.addAssets([asset] as NSFastEnumeration)
            }
            return true
        } catch {
            print("Error adding photo to album: \(error)")
            return false
        }
    }

    /// Open app settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Thumbnail Generator
/// Generates 1280x720 JPEG thumbnails from images
struct ThumbnailGenerator {
    static let targetWidth: CGFloat = 1280
    static let targetHeight: CGFloat = 720
    static let jpegQuality: CGFloat = 0.75

    /// Check if image is portrait orientation
    static func isPortrait(_ image: UIImage) -> Bool {
        return image.size.height > image.size.width
    }

    /// Generate 1280x720 JPEG thumbnail from UIImage
    /// Portrait images are letterboxed with black bars
    static func generateThumbnail(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        // Create drawing context with black background
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Fill with black background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: targetSize))

        // Calculate scaling and positioning
        let imageSize = image.size
        let widthRatio = targetWidth / imageSize.width
        let heightRatio = targetHeight / imageSize.height

        // Use the smaller ratio to fit image within bounds
        let scale = min(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        // Center the image
        let x = (targetWidth - scaledWidth) / 2
        let y = (targetHeight - scaledHeight) / 2

        let drawRect = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
        image.draw(in: drawRect)

        guard let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }

        // Compress as JPEG
        return thumbnailImage.jpegData(compressionQuality: jpegQuality)
    }

    /// Generate thumbnail from PHAsset
    static func generateThumbnail(from asset: PHAsset) async -> Data? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            // Request a reasonably large image to scale down from
            let requestSize = CGSize(width: 2560, height: 1440)

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: requestSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image = image {
                    continuation.resume(returning: generateThumbnail(from: image))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Photo Picker View
/// SwiftUI wrapper for PHPickerViewController
struct PhotoPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (UIImage, String) -> Void  // (image, localIdentifier)
    let onCancel: () -> Void

    init(onSelect: @escaping (UIImage, String) -> Void, onCancel: @escaping () -> Void = {}) {
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                parent.onCancel()
                return
            }

            // Get the asset identifier
            let assetIdentifier = result.assetIdentifier ?? ""

            // Load the image
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    DispatchQueue.main.async {
                        if let image = object as? UIImage {
                            self?.parent.dismiss()
                            self?.parent.onSelect(image, assetIdentifier)
                        } else {
                            self?.parent.dismiss()
                            self?.parent.onCancel()
                        }
                    }
                }
            } else {
                parent.dismiss()
                parent.onCancel()
            }
        }
    }
}

// MARK: - Full Screen Photo Viewer
/// Zoomable full-screen photo viewer
struct FullScreenPhotoViewer: View {
    let localIdentifier: String
    let thumbnailData: Data?

    @Environment(\.dismiss) private var dismiss
    @State private var fullSizeImage: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingOpenInPhotosAlert = false

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()

                // Image content
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if let image = fullSizeImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(max(newScale, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale <= minScale {
                                        withAnimation(.spring()) {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > minScale {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > minScale {
                                    scale = minScale
                                    lastScale = minScale
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                } else if let data = thumbnailData, let thumbnail = UIImage(data: data) {
                    // Fallback to thumbnail if full-size not available
                    VStack(spacing: 16) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        Text("Showing thumbnail - original not available")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("Unable to load photo")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Controls overlay
                VStack {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button(action: { showingOpenInPhotosAlert = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle")
                                Text("View in Photos")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .task {
            await loadFullSizeImage()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if scale <= minScale && value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
        .alert("View in Photos", isPresented: $showingOpenInPhotosAlert) {
            Button("Open Photos") {
                PhotoLibraryManager.shared.openPhotosApp()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Find this photo in the Airplane-ID album")
        }
    }

    private func loadFullSizeImage() async {
        isLoading = true

        if let image = await PhotoLibraryManager.shared.fetchFullSizeImage(localIdentifier: localIdentifier) {
            fullSizeImage = image
            loadError = false
        } else {
            loadError = true
        }

        isLoading = false
    }
}

// MARK: - Photo Permission View
/// Blocking overlay shown when photo library permission is denied
/// User must grant permission in Settings to use the app
struct PhotoPermissionView: View {
    var body: some View {
        ZStack {
            // Opaque dark background - completely blocks app
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "photo.badge.exclamationmark.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.orange)

                // Title
                Text("Photo Access Required")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                // Message
                Text("Photo library access is required for Airplane-ID to function.\n\nPlease grant full access in Settings, then return to this app.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Settings button
                Button(action: {
                    PhotoLibraryManager.shared.openSettings()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryBlue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Thumbnail Image View
/// Reusable view for displaying thumbnail from Data
struct ThumbnailImageView: View {
    let thumbnailData: Data?
    var contentMode: ContentMode = .fill

    var body: some View {
        if let data = thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            // Placeholder
            Rectangle()
                .fill(AppColors.darkBlue.opacity(0.3))
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Aircraft Photo")
                            .font(.custom("Helvetica", size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
        }
    }
}

// MARK: - Preview
#Preview("Permission View") {
    PhotoPermissionView()
}

#Preview("Photo Viewer") {
    FullScreenPhotoViewer(
        localIdentifier: "",
        thumbnailData: nil
    )
}
