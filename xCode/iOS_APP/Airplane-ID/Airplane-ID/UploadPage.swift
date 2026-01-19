//
//  UploadPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/18/26.
//
//  Photo upload workflow for manually creating aircraft sighting records.
//  - Select photo from library or Files app
//  - Enter aircraft details (ICAO, Airline, Registration)
//  - Scanning animation (placeholder for future AI)
//  - Results display with thumbs up/down feedback
//  - Save to database and photo library
//

import SwiftUI
import SwiftData
import Photos

// MARK: - Upload State
/// State machine for the upload workflow
enum UploadState {
    case selectPhoto           // Initial state - show source selection buttons
    case enterDetails          // Photo selected - show form
    case scanning              // Processing animation (placeholder for future AI)
    case results               // Show results with feedback options
}

// MARK: - Upload Form Data
/// Observable class holding all form data for the upload workflow
@Observable
class UploadFormData {
    // Photo data
    var selectedImage: UIImage?
    var photoIdentifier: String?        // PHAsset localIdentifier (for library photos)
    var isFromFilesApp: Bool = false    // true if imported from Files

    // User input
    var selectedICAO: String?           // From ICAOSearchSheet
    var selectedAirlineCode: String?    // From AirlineSearchSheet (optional)
    var registration: String = ""       // Free-form (optional)
    var captureDateTime: Date = Date()  // Date picker

    // ICAO lookup results (populated after ICAO selection)
    var manufacturer: String?
    var model: String?
    var icaoClass: String?
    var aircraftCategoryCode: Int?
    var aircraftType: String?
    var engineCount: Int?
    var engineType: Int?

    // Feedback
    var thumbsUp: Bool?                 // nil = not rated, true = 👍, false = 👎

    var isValid: Bool {
        selectedImage != nil && selectedICAO != nil
    }

    func reset() {
        selectedImage = nil
        photoIdentifier = nil
        isFromFilesApp = false
        selectedICAO = nil
        selectedAirlineCode = nil
        registration = ""
        captureDateTime = Date()
        manufacturer = nil
        model = nil
        icaoClass = nil
        aircraftCategoryCode = nil
        aircraftType = nil
        engineCount = nil
        engineType = nil
        thumbsUp = nil
    }
}

// MARK: - Upload Page
/// Main upload view with state-driven content
struct UploadPage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var uploadState: UploadState = .selectPhoto
    @State private var formData = UploadFormData()

    // Sheet states
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingICAOSearch = false
    @State private var showingAirlineSearch = false

    // Animation
    @State private var scanAngle: Double = 0

    var body: some View {
        OrientationAwarePage(
            portrait: { uploadContent },
            leftHorizontal: { uploadContent.padding(.leading, 120) },
            rightHorizontal: { uploadContent.padding(.trailing, 120) }
        )
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(
                onSelect: { image, identifier in
                    formData.selectedImage = image
                    formData.photoIdentifier = identifier
                    formData.isFromFilesApp = false
                    uploadState = .enterDetails
                },
                onCancel: { }
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(
                onSelect: { image in
                    formData.selectedImage = image
                    formData.photoIdentifier = nil
                    formData.isFromFilesApp = true
                    uploadState = .enterDetails
                },
                onCancel: { }
            )
        }
        .sheet(isPresented: $showingICAOSearch) {
            ICAOSearchSheet(selectedICAO: Binding(
                get: { formData.selectedICAO },
                set: { newValue in
                    if let icao = newValue {
                        handleICAOSelection(icao)
                    }
                }
            ))
        }
        .sheet(isPresented: $showingAirlineSearch) {
            AirlineSearchSheet(selectedAirlineCode: Binding(
                get: { formData.selectedAirlineCode },
                set: { formData.selectedAirlineCode = $0 }
            ))
        }
    }

    @ViewBuilder
    private var uploadContent: some View {
        switch uploadState {
        case .selectPhoto:
            selectPhotoView
        case .enterDetails:
            enterDetailsView
        case .scanning:
            scanningView
        case .results:
            resultsView
        }
    }

    // MARK: - Select Photo View
    private var selectPhotoView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.6))

            Text("Add Aircraft")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Select a photo to identify")
                .foregroundStyle(.white.opacity(0.7))

            VStack(spacing: 16) {
                // Photo Library button
                Button(action: {
                    Haptics.light()
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Photo Library")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryBlue)
                    .cornerRadius(12)
                }

                // Files button
                Button(action: {
                    Haptics.light()
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Browse Files")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.mediumGray)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Enter Details View
    private var enterDetailsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo preview (16:9 aspect ratio)
                if let image = formData.selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.width * 9/16)
                            .clipped()
                            .cornerRadius(12)

                        // Change photo button
                        Button(action: {
                            Haptics.light()
                            formData.reset()
                            uploadState = .selectPhoto
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                }

                // ICAO Search (Required)
                UploadPickerRow(
                    label: "Aircraft Type",
                    value: formData.selectedICAO,
                    placeholder: "Select aircraft type...",
                    isRequired: true,
                    onTap: { showingICAOSearch = true }
                )

                // Airline Search (Optional)
                UploadPickerRow(
                    label: "Airline",
                    value: formData.selectedAirlineCode,
                    placeholder: "Select airline (optional)",
                    isRequired: false,
                    onTap: { showingAirlineSearch = true }
                )

                // Registration (Optional)
                UploadTextField(
                    label: "Registration",
                    placeholder: "e.g. N12345 (optional)",
                    text: $formData.registration
                )

                // Date/Time Picker
                UploadDateTimeRow(
                    label: "Spotted On",
                    selectedDate: $formData.captureDateTime
                )

                // Submit Button
                Button(action: submitForScanning) {
                    Text("Submit")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(formData.isValid ? AppColors.primaryBlue : AppColors.mediumGray)
                        .cornerRadius(12)
                }
                .disabled(!formData.isValid)
            }
            .padding()
        }
    }

    // MARK: - Scanning View
    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated radar-style scanner
            ZStack {
                Circle()
                    .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)

                Image(systemName: "airplane")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.orange)
                    .rotationEffect(.degrees(-45))

                // Rotating sweep line
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(AppColors.gold, lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(scanAngle))
            }

            Text("Scanning Aircraft...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text("Identifying aircraft type")
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .onAppear {
            // Start rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                scanAngle = 360
            }

            // Simulate AI processing (2.5 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                populateFromICAOLookup()
                uploadState = .results
            }
        }
    }

    // MARK: - Results View
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo
                if let image = formData.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: UIScreen.main.bounds.width * 9/16)
                        .clipped()
                        .cornerRadius(12)
                }

                // Aircraft Identification
                VStack(alignment: .leading, spacing: 4) {
                    Text(formData.manufacturer?.uppercased() ?? "UNKNOWN")
                        .font(.custom("Helvetica-Bold", size: 24))
                        .foregroundStyle(.white)
                    Text(formData.model ?? "Unknown Model")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Specs from ICAO lookup (read-only display)
                VStack(spacing: 8) {
                    if let typeName = AircraftLookup.typeName(formData.aircraftType) {
                        UploadResultRow(label: "Type", value: typeName)
                    }
                    if let engineType = formData.engineType {
                        UploadResultRow(label: "Engine", value: AircraftLookup.engineTypeName(engineType) ?? "Unknown")
                    }
                    if let engineCount = formData.engineCount, engineCount > 0 {
                        UploadResultRow(label: "Engines", value: "\(engineCount)")
                    }
                }
                .padding()
                .background(AppColors.settingsRow)
                .cornerRadius(10)

                // Thumbs Up/Down Feedback
                VStack(spacing: 8) {
                    Text("How did we do?")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))

                    HStack(spacing: 40) {
                        Button(action: {
                            formData.thumbsUp = true
                            Haptics.light()
                        }) {
                            VStack {
                                Image(systemName: formData.thumbsUp == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.system(size: 32))
                                Text("Correct")
                                    .font(.caption)
                            }
                            .foregroundStyle(formData.thumbsUp == true ? AppColors.success : .white.opacity(0.7))
                        }

                        Button(action: {
                            formData.thumbsUp = false
                            Haptics.light()
                        }) {
                            VStack {
                                Image(systemName: formData.thumbsUp == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.system(size: 32))
                                Text("Wrong")
                                    .font(.caption)
                            }
                            .foregroundStyle(formData.thumbsUp == false ? AppColors.error : .white.opacity(0.7))
                        }
                    }
                }

                // Save Button
                Button(action: { Task { await saveAircraft() } }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Hangar")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryBlue)
                    .cornerRadius(12)
                }

                // Start Over Button
                Button(action: {
                    Haptics.light()
                    formData.reset()
                    scanAngle = 0
                    uploadState = .selectPhoto
                }) {
                    Text("Start Over")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func submitForScanning() {
        Haptics.selection()
        uploadState = .scanning
    }

    private func handleICAOSelection(_ icao: String) {
        formData.selectedICAO = icao

        // Fetch ICAO lookup data
        let descriptor = FetchDescriptor<ICAOLookup>(
            predicate: #Predicate { $0.icao == icao }
        )

        if let lookup = try? modelContext.fetch(descriptor).first {
            formData.manufacturer = lookup.manufacturer
            formData.model = lookup.model
            formData.icaoClass = lookup.icaoClass
            formData.aircraftCategoryCode = lookup.aircraftCategoryCode
            formData.aircraftType = lookup.aircraftType
            formData.engineCount = lookup.engineCount
            formData.engineType = lookup.engineType
        }
    }

    private func populateFromICAOLookup() {
        // Called during scanning phase to ensure data is populated
        if let icao = formData.selectedICAO {
            handleICAOSelection(icao)
        }
    }

    @MainActor
    private func saveAircraft() async {
        guard let image = formData.selectedImage,
              let icao = formData.selectedICAO,
              let manufacturer = formData.manufacturer,
              let model = formData.model else { return }

        // 1. Generate thumbnail (1280x720 JPEG)
        let thumbnailData = ThumbnailGenerator.generateThumbnail(from: image)

        // 2. Handle photo storage
        var photoIdentifier = formData.photoIdentifier ?? ""

        if formData.isFromFilesApp {
            // For files import: save to photo library first
            photoIdentifier = await saveImageToPhotoLibrary(image)
        }

        // 3. Add to Airplane-ID album
        if !photoIdentifier.isEmpty {
            _ = await PhotoLibraryManager.shared.addPhotoToAppAlbum(localIdentifier: photoIdentifier)
        }

        // 4. Extract date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: formData.captureDateTime)

        // 5. Create CapturedAircraft record
        let aircraft = CapturedAircraft(
            captureTime: formData.captureDateTime,
            captureDate: calendar.startOfDay(for: formData.captureDateTime),
            year: components.year ?? 2026,
            month: components.month ?? 1,
            day: components.day ?? 1,
            gpsLongitude: 0,  // TODO: Extract from photo EXIF if available
            gpsLatitude: 0,
            iPhotoReference: photoIdentifier,
            thumbnailData: thumbnailData,
            icao: icao,
            manufacturer: manufacturer,
            model: model,
            airlineCode: formData.selectedAirlineCode,
            registration: formData.registration.isEmpty ? nil : formData.registration.uppercased(),
            aircraftCategoryCode: formData.aircraftCategoryCode,
            aircraftType: formData.aircraftType,
            engineType: formData.engineType,
            engineCount: formData.engineCount,
            thumbsUp: formData.thumbsUp
        )

        // 6. Insert and save
        modelContext.insert(aircraft)
        try? modelContext.save()

        // 7. Success feedback
        Haptics.success()

        // 8. Reset form and return to select photo state
        formData.reset()
        scanAngle = 0
        uploadState = .selectPhoto
    }

    /// Save image from Files app to Photo Library
    private func saveImageToPhotoLibrary(_ image: UIImage) async -> String {
        return await withCheckedContinuation { continuation in
            var localId = ""
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
            } completionHandler: { success, error in
                continuation.resume(returning: localId)
            }
        }
    }
}

// MARK: - Helper Components

/// Picker row for ICAO/Airline selection
struct UploadPickerRow: View {
    let label: String
    let value: String?
    let placeholder: String
    let isRequired: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                if isRequired {
                    Text("*")
                        .foregroundStyle(AppColors.orange)
                }
            }

            Button(action: {
                Haptics.light()
                onTap()
            }) {
                HStack {
                    Text(value ?? placeholder)
                        .foregroundStyle(value != nil ? .white : .white.opacity(0.5))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding()
                .background(AppColors.settingsRow)
                .cornerRadius(10)
            }
        }
    }
}

/// Text field for registration input
struct UploadTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding()
                .background(AppColors.settingsRow)
                .cornerRadius(10)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
        }
    }
}

/// Date/Time picker row
struct UploadDateTimeRow: View {
    let label: String
    @Binding var selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))

            HStack {
                DatePicker("", selection: $selectedDate)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                Spacer()
            }
            .padding()
            .background(AppColors.settingsRow)
            .cornerRadius(10)
        }
    }
}

/// Result display row
struct UploadResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Previews

#Preview("Portrait - Select Photo") {
    UploadPage()
        .environment(AppState())
        .modelContainer(for: [CapturedAircraft.self, ICAOLookup.self, AirlineLookup.self])
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Add Aircraft")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("Select a photo to identify")
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.leading, 120)
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Add Aircraft")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("Select a photo to identify")
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.trailing, 120)
    }
    .environment(AppState())
}
