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
import CoreLocation

// MARK: - Upload State
/// State machine for the upload workflow
enum UploadState {
    case enterDetails          // Initial/form entry state
    case imageScan             // Green scan lines animation on image
    case scanning              // Processing animation (radar spinner)
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
    var imageData: Data?                // Raw image data (for Files imports - needed for EXIF extraction)

    // GPS coordinates (extracted from photo metadata)
    var gpsLatitude: Double = 0
    var gpsLongitude: Double = 0
    var hasGPS: Bool { gpsLatitude != 0 || gpsLongitude != 0 }

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

    /// Check if photo and ICAO are selected
    var isValid: Bool {
        selectedImage != nil && selectedICAO != nil
    }

    /// Check if user has entered any data (for showing CLEAR button)
    var hasUserInput: Bool {
        selectedICAO != nil || selectedAirlineCode != nil || !registration.isEmpty
    }

    func reset() {
        selectedImage = nil
        photoIdentifier = nil
        isFromFilesApp = false
        imageData = nil
        gpsLatitude = 0
        gpsLongitude = 0
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

    /// Clear only the form fields (not the photo)
    func clearFormFields() {
        selectedICAO = nil
        selectedAirlineCode = nil
        registration = ""
        manufacturer = nil
        model = nil
        icaoClass = nil
        aircraftCategoryCode = nil
        aircraftType = nil
        engineCount = nil
        engineType = nil
    }
}

// MARK: - Upload Page
/// Main upload view with state-driven content
struct UploadPage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var uploadState: UploadState = .enterDetails
    @State private var formData = UploadFormData()

    // Sheet states
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingICAOSearch = false
    @State private var showingAirlineSearch = false

    // Alert states
    @State private var showingPortraitWarning = false
    @State private var showingMissingDataAlert = false
    @State private var showingMissingRatingAlert = false
    @State private var pendingPhoto: (image: UIImage, identifier: String?, imageData: Data?)?

    // Animation states
    @State private var scanAngle: Double = 0
    @State private var visibleLines: Int = 0
    @State private var scanPhase: ScanPhase = .idle
    @State private var showProcessedText: Bool = false

    var body: some View {
        OrientationAwarePage(
            portrait: { uploadContent },
            leftHorizontal: { uploadContent.padding(.leading, 120) },
            rightHorizontal: { uploadContent.padding(.trailing, 120) }
        )
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(
                onSelect: { image, identifier in
                    handlePhotoSelected(image: image, identifier: identifier)
                },
                onCancel: { }
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(
                onSelect: { image, imageData in
                    handlePhotoSelectedFromFiles(image: image, imageData: imageData)
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
        .alert("Portrait Photo Detected", isPresented: $showingPortraitWarning) {
            Button("Use Anyway") {
                if let photo = pendingPhoto {
                    formData.selectedImage = photo.image
                    formData.photoIdentifier = photo.identifier
                    formData.isFromFilesApp = photo.identifier == nil
                    formData.imageData = photo.imageData

                    // Extract GPS and date from the accepted portrait photo
                    if let identifier = photo.identifier {
                        // Photo Library - extract from PHAsset
                        let metadata = PhotoLibraryManager.shared.getMetadata(from: identifier)
                        if let coordinate = metadata.gps {
                            formData.gpsLatitude = coordinate.latitude
                            formData.gpsLongitude = coordinate.longitude
                        } else {
                            formData.gpsLatitude = 0
                            formData.gpsLongitude = 0
                        }
                        if let date = metadata.date {
                            formData.captureDateTime = date
                        }
                    } else if let imageData = photo.imageData {
                        // Files app - extract from EXIF
                        let metadata = EXIFExtractor.extractMetadata(from: imageData)
                        if let coordinate = metadata.gps {
                            formData.gpsLatitude = coordinate.latitude
                            formData.gpsLongitude = coordinate.longitude
                        } else {
                            formData.gpsLatitude = 0
                            formData.gpsLongitude = 0
                        }
                        if let date = metadata.date {
                            formData.captureDateTime = date
                        }
                    } else {
                        formData.gpsLatitude = 0
                        formData.gpsLongitude = 0
                    }

                    pendingPhoto = nil
                }
            }
            Button("Choose Different", role: .cancel) {
                pendingPhoto = nil
                showingPhotoPicker = true
            }
        } message: {
            Text("You are attempting to upload a photo in portrait orientation. Our app is optimized for landscape images. Would you like to continue or upload a different image?")
        }
        .alert("Missing Information", isPresented: $showingMissingDataAlert) {
            Button("Return") {
                // Stay on form
            }
            Button("Process Anyway") {
                startImageScan()
            }
        } message: {
            Text("Please select Aircraft Type and Registration. This info helps improve the accuracy of the AI model.")
        }
        .alert("Rate the Results", isPresented: $showingMissingRatingAlert) {
            Button("Return") {
                // Stay on results to rate
            }
            Button("Save Anyway") {
                Task { await saveAircraftConfirmed() }
            }
        } message: {
            Text("Please rate the identification results using thumbs up or down. This helps us improve the AI model accuracy.")
        }
    }

    @ViewBuilder
    private var uploadContent: some View {
        switch uploadState {
        case .enterDetails:
            enterDetailsView
        case .imageScan:
            imageScanView
        case .scanning:
            scanningView
        case .results:
            resultsView
        }
    }

    // MARK: - Enter Details View
    private var enterDetailsView: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 30  // 15px padding each side

            ScrollView {
                VStack(spacing: 0) {
                    // Photo placeholder / preview area (16:9 aspect ratio)
                    photoPreviewArea(width: contentWidth)
                        .padding(.horizontal, 15)
                        .padding(.top, 10)

                    // Photo source buttons
                    VStack(spacing: 12) {
                        UploadSourceButton(
                            icon: "photo.on.rectangle",
                            title: "Photo Library",
                            subtitle: "Select from your photos"
                        ) {
                            Haptics.light()
                            showingPhotoPicker = true
                        }

                        UploadSourceButton(
                            icon: "folder",
                            title: "Browse Files",
                            subtitle: "Import from iCloud, Dropbox, etc."
                        ) {
                            Haptics.light()
                            showingDocumentPicker = true
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 15)

                    // Row 1: Aircraft Type & Airline (side by side)
                    HStack(spacing: 12) {
                        // Aircraft Type (ICAO)
                        UploadCompactPicker(
                            label: "Aircraft Type",
                            value: formData.selectedICAO,
                            placeholder: "Select"
                        ) {
                            Haptics.light()
                            showingICAOSearch = true
                        }

                        // Airline
                        UploadCompactPicker(
                            label: "Airline",
                            value: formData.selectedAirlineCode,
                            placeholder: "Select"
                        ) {
                            Haptics.light()
                            showingAirlineSearch = true
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)

                    // Row 2: Registration & Date (side by side)
                    HStack(spacing: 12) {
                        // Registration - gets more space
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Registration")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))

                            TextField("", text: $formData.registration)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(AppColors.settingsRow)
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                        }
                        .frame(maxWidth: .infinity)

                        // Date only (no time) - fixed width, pinned right
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spotted On")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))

                            DatePicker("", selection: $formData.captureDateTime, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .frame(height: 36)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)

                    // Submit box
                    submitBox(width: contentWidth)
                        .padding(.horizontal, 15)
                        .padding(.top, 15)

                    // CLEAR button (only visible when user has input)
                    if formData.hasUserInput {
                        Button(action: {
                            Haptics.light()
                            formData.reset()
                        }) {
                            Text("CLEAR")
                                .font(.custom("Helvetica-Bold", size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.orange)
                                .cornerRadius(6)
                        }
                        .padding(.top, 12)
                    }

                    Spacer(minLength: 100) // Space for footer
                }
                .padding(.bottom, 25)
            }
        }
    }

    // MARK: - Photo Preview Area
    @ViewBuilder
    private func photoPreviewArea(width: CGFloat) -> some View {
        let height = width * 9/16

        ZStack {
            if let image = formData.selectedImage {
                // Show selected image
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(10)

                    // Remove photo button
                    Button(action: {
                        Haptics.light()
                        formData.selectedImage = nil
                        formData.photoIdentifier = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                // Show placeholder - darker with video-like color hint
                ZStack {
                    // Base dark background
                    Rectangle()
                        .fill(AppColors.darkBlue.opacity(0.6))

                    // Subtle horizontal scanlines for video effect
                    Canvas { context, size in
                        for y in stride(from: 0, to: size.height, by: 4) {
                            let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                            context.fill(Path(rect), with: .color(.black.opacity(0.15)))
                        }
                    }

                    // Content
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Add Photo")
                            .font(.custom("Helvetica", size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(width: width, height: height)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Submit Box
    @ViewBuilder
    private func submitBox(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                AppColors.darkBlue
                Text("Submit")
                    .font(.custom("Helvetica-Bold", size: 14))
                    .foregroundStyle(.white)
            }
            .frame(width: width, height: 28)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

            // Body
            ZStack {
                AppColors.white

                Button(action: handleSubmitTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                        Text("Identify Aircraft")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(formData.selectedImage != nil ? AppColors.primaryBlue : AppColors.mediumGray)
                    .cornerRadius(8)
                }
                .disabled(formData.selectedImage == nil)
            }
            .frame(width: width, height: 70)
            .overlay(
                RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                    .stroke(AppColors.borderBlue, lineWidth: 1)
            )
            .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
        }
    }

    // MARK: - Image Scan View (Animated X-pattern grid scan)
    private var imageScanView: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 30
            let imageHeight = contentWidth * 9/16

            ZStack {
                // Dark background
                Color.black

                VStack {
                    Spacer()

                    // Image with scan effect overlay
                    ZStack {
                        // The image
                        if let image = formData.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: contentWidth, height: imageHeight)
                                .clipped()
                                .cornerRadius(10)
                        }

                        // X-pattern grid scan overlay
                        XPatternScanOverlay(
                            visibleLines: visibleLines,
                            phase: scanPhase,
                            lineSpacing: 30
                        )
                        .frame(width: contentWidth, height: imageHeight)
                        .cornerRadius(10)
                        .clipped()

                        // White flash with PROCESSED text
                        if showProcessedText {
                            ZStack {
                                Color.white

                                Text("PROCESSED")
                                    .font(.custom("Helvetica-Bold", size: 40))
                                    .foregroundStyle(Color.gray.opacity(0.3))
                            }
                            .frame(width: contentWidth, height: imageHeight)
                            .cornerRadius(10)
                        }
                    }

                    Spacer()

                    // Status text
                    Text(showProcessedText ? "Complete!" : "Scanning Image...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 50)

                    Spacer()
                }
            }
        }
        .onAppear {
            startXPatternScan()
        }
    }

    // MARK: - Scanning View (Radar spinner)
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

            Text("Identifying Aircraft...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text("Processing with AI")
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
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 30

            ScrollView {
                VStack(spacing: 0) {
                    // Photo preview
                    if let image = formData.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: contentWidth, height: contentWidth * 9/16)
                            .clipped()
                            .cornerRadius(10)
                            .padding(.horizontal, 15)
                            .padding(.top, 10)
                    }

                    // Results box
                    resultsBox(width: contentWidth)
                        .padding(.horizontal, 15)
                        .padding(.top, 15)
                        .padding(.bottom, 15)

                    // Start Over button (orange box style)
                    Button(action: {
                        Haptics.light()
                        resetAllState()
                    }) {
                        Text("START OVER")
                            .font(.custom("Helvetica-Bold", size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.orange)
                            .cornerRadius(6)
                    }
                    .padding(.bottom, 20)

                    Spacer(minLength: 100)
                }
            }
        }
    }

    // MARK: - Results Box
    @ViewBuilder
    private func resultsBox(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                AppColors.darkBlue
                Text("Aircraft Identified")
                    .font(.custom("Helvetica-Bold", size: 14))
                    .foregroundStyle(.white)
            }
            .frame(width: width, height: 28)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

            // Body
            VStack(spacing: 12) {
                // Row 1: Manufacturer & Model
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manufacturer")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(formData.manufacturer?.uppercased() ?? "UNKNOWN")
                            .font(.custom("Helvetica-Bold", size: 16))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(formData.model ?? "Unknown")
                            .font(.custom("Helvetica-Bold", size: 16))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Row 2: Registration & Classification
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Registration")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(formData.registration.isEmpty ? "—" : formData.registration.uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Classification")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(AircraftLookup.classificationName(formData.aircraftCategoryCode) ?? "—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Row 3: Type & Category
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Type")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(AircraftLookup.typeName(formData.aircraftType) ?? "—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        Text(AircraftLookup.icaoClassDisplayName(formData.icaoClass) ?? "—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Row 4: Engine Type & Number of Engines
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Engine Type")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        if let engineType = formData.engineType,
                           let engineName = AircraftLookup.engineTypeName(engineType) {
                            Text(engineName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.darkBlue)
                        } else {
                            Text("—")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.darkBlue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Num Engines")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                        if let count = formData.engineCount, count > 0 {
                            Text("\(count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.darkBlue)
                        } else {
                            Text("—")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.darkBlue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                    .background(AppColors.borderBlue)

                // Feedback row: Thumbs Down - Save Button - Thumbs Up
                HStack(spacing: 0) {
                    // Thumbs Down
                    Button(action: {
                        formData.thumbsUp = false
                        Haptics.light()
                    }) {
                        Image(systemName: formData.thumbsUp == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 28))
                            .foregroundStyle(formData.thumbsUp == false ? AppColors.error : AppColors.darkBlue.opacity(0.4))
                    }
                    .frame(width: 50)

                    Spacer()

                    // Save Button
                    Button(action: handleSaveTapped) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text("Save to Hangar")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(8)
                    }

                    Spacer()

                    // Thumbs Up
                    Button(action: {
                        formData.thumbsUp = true
                        Haptics.light()
                    }) {
                        Image(systemName: formData.thumbsUp == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 28))
                            .foregroundStyle(formData.thumbsUp == true ? AppColors.success : AppColors.darkBlue.opacity(0.4))
                    }
                    .frame(width: 50)
                }
            }
            .padding(16)
            .frame(width: width)
            .background(AppColors.white)
            .overlay(
                RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                    .stroke(AppColors.borderBlue, lineWidth: 1)
            )
            .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
        }
    }

    // MARK: - Actions

    private func handlePhotoSelected(image: UIImage, identifier: String) {
        if ThumbnailGenerator.isPortrait(image) {
            pendingPhoto = (image, identifier, nil)
            showingPortraitWarning = true
        } else {
            formData.selectedImage = image
            formData.photoIdentifier = identifier
            formData.isFromFilesApp = false
            formData.imageData = nil

            // Extract GPS and date from PHAsset
            let metadata = PhotoLibraryManager.shared.getMetadata(from: identifier)

            if let coordinate = metadata.gps {
                formData.gpsLatitude = coordinate.latitude
                formData.gpsLongitude = coordinate.longitude
                #if DEBUG
                print("GPS extracted from Photo Library: \(coordinate.latitude), \(coordinate.longitude)")
                #endif
            } else {
                formData.gpsLatitude = 0
                formData.gpsLongitude = 0
            }

            if let date = metadata.date {
                formData.captureDateTime = date
                #if DEBUG
                print("Date extracted from Photo Library: \(date)")
                #endif
            }
        }
    }

    private func handlePhotoSelectedFromFiles(image: UIImage, imageData: Data) {
        if ThumbnailGenerator.isPortrait(image) {
            pendingPhoto = (image, nil, imageData)
            showingPortraitWarning = true
        } else {
            formData.selectedImage = image
            formData.photoIdentifier = nil
            formData.isFromFilesApp = true
            formData.imageData = imageData

            // Extract GPS and date from EXIF metadata
            let metadata = EXIFExtractor.extractMetadata(from: imageData)

            if let coordinate = metadata.gps {
                formData.gpsLatitude = coordinate.latitude
                formData.gpsLongitude = coordinate.longitude
                #if DEBUG
                print("GPS extracted from EXIF: \(coordinate.latitude), \(coordinate.longitude)")
                #endif
            } else {
                formData.gpsLatitude = 0
                formData.gpsLongitude = 0
            }

            if let date = metadata.date {
                formData.captureDateTime = date
                #if DEBUG
                print("Date extracted from EXIF: \(date)")
                #endif
            }
        }
    }

    private func handleSubmitTapped() {
        guard formData.selectedImage != nil else { return }

        // Check if Aircraft Type or Registration is missing
        if formData.selectedICAO == nil || formData.registration.isEmpty {
            Haptics.warning()
            showingMissingDataAlert = true
        } else {
            startImageScan()
        }
    }

    private func startImageScan() {
        Haptics.selection()
        // Reset scan state
        visibleLines = 0
        scanPhase = .idle
        showProcessedText = false
        uploadState = .imageScan
    }

    private func startXPatternScan() {
        // Calculate total lines needed (approximately)
        let totalLinesPerDirection = 20  // Adjust based on spacing
        let delayBetweenLines: Double = 0.025  // 25ms between lines

        // Phase 1: Draw lines from top-left to bottom-right
        scanPhase = .topLeftToBottomRight
        for i in 0..<totalLinesPerDirection {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delayBetweenLines) {
                visibleLines = i + 1
            }
        }

        // Phase 2: Draw lines from top-right to bottom-left
        let phase2Start = Double(totalLinesPerDirection) * delayBetweenLines
        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start) {
            scanPhase = .topRightToBottomLeft
            visibleLines = 0
        }

        for i in 0..<totalLinesPerDirection {
            DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start + Double(i) * delayBetweenLines) {
                visibleLines = i + 1
            }
        }

        // Phase 3: Flash with PROCESSED
        let flashStart = phase2Start + Double(totalLinesPerDirection) * delayBetweenLines
        DispatchQueue.main.asyncAfter(deadline: .now() + flashStart) {
            withAnimation(.easeIn(duration: 0.1)) {
                showProcessedText = true
            }

            // Transition after showing PROCESSED for 0.6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                uploadState = .scanning
            }
        }
    }

    private func resetAllState() {
        formData.reset()
        scanAngle = 0
        visibleLines = 0
        scanPhase = .idle
        showProcessedText = false
        uploadState = .enterDetails
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
        if let icao = formData.selectedICAO {
            handleICAOSelection(icao)
        }
    }

    private func handleSaveTapped() {
        // Check if user has rated the results
        if formData.thumbsUp == nil {
            Haptics.warning()
            showingMissingRatingAlert = true
        } else {
            Task { await saveAircraftConfirmed() }
        }
    }

    @MainActor
    private func saveAircraftConfirmed() async {
        guard let image = formData.selectedImage,
              let icao = formData.selectedICAO,
              let manufacturer = formData.manufacturer,
              let model = formData.model else { return }

        // 1. Generate thumbnail (1280x720 JPEG)
        let thumbnailData = ThumbnailGenerator.generateThumbnail(from: image)

        // 2. Handle photo storage
        var photoIdentifier = formData.photoIdentifier ?? ""

        if formData.isFromFilesApp {
            photoIdentifier = await saveImageToPhotoLibrary(image)
        }

        // 3. Add to Airplane-ID album
        if !photoIdentifier.isEmpty {
            _ = await PhotoLibraryManager.shared.addPhotoToAppAlbum(localIdentifier: photoIdentifier)
        }

        // 4. Extract date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: formData.captureDateTime)

        // 5. Create CapturedAircraft record with extracted GPS coordinates
        let aircraft = CapturedAircraft(
            captureTime: formData.captureDateTime,
            captureDate: calendar.startOfDay(for: formData.captureDateTime),
            year: components.year ?? 2026,
            month: components.month ?? 1,
            day: components.day ?? 1,
            gpsLongitude: formData.gpsLongitude,
            gpsLatitude: formData.gpsLatitude,
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

        // 8. Reset form
        resetAllState()
    }

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

// MARK: - Scan Phase
enum ScanPhase {
    case idle
    case topLeftToBottomRight
    case topRightToBottomLeft
}

// MARK: - X-Pattern Scan Overlay
/// Animated X-pattern grid with lines drawn sequentially
struct XPatternScanOverlay: View {
    let visibleLines: Int
    let phase: ScanPhase
    let lineSpacing: CGFloat

    // Persistent state for completed phases
    @State private var phase1Complete: Bool = false

    var body: some View {
        Canvas { context, size in
            let lineWidth: CGFloat = 1
            let greenColor = Color(hex: "00FF00").opacity(0.8)

            // Always draw phase 1 lines if completed or currently drawing
            if phase == .topLeftToBottomRight || phase1Complete || phase == .topRightToBottomLeft {
                let linesToDraw = phase == .topLeftToBottomRight ? visibleLines : Int(ceil((size.width + size.height) / lineSpacing))

                // Draw top-left to bottom-right diagonal lines
                var lineIndex = 0
                var startX: CGFloat = -size.height
                while startX < size.width && lineIndex < linesToDraw {
                    let path = Path { p in
                        p.move(to: CGPoint(x: startX, y: 0))
                        p.addLine(to: CGPoint(x: startX + size.height, y: size.height))
                    }
                    context.stroke(path, with: .color(greenColor), lineWidth: lineWidth)
                    startX += lineSpacing
                    lineIndex += 1
                }
            }

            // Draw phase 2 lines (top-right to bottom-left)
            if phase == .topRightToBottomLeft {
                var lineIndex = 0
                var startX: CGFloat = size.width + size.height
                while startX > 0 && lineIndex < visibleLines {
                    let path = Path { p in
                        p.move(to: CGPoint(x: startX, y: 0))
                        p.addLine(to: CGPoint(x: startX - size.height, y: size.height))
                    }
                    context.stroke(path, with: .color(greenColor), lineWidth: lineWidth)
                    startX -= lineSpacing
                    lineIndex += 1
                }
            }
        }
        .onChange(of: phase) { oldPhase, newPhase in
            if oldPhase == .topLeftToBottomRight && newPhase == .topRightToBottomLeft {
                phase1Complete = true
            }
            if newPhase == .idle {
                phase1Complete = false
            }
        }
    }
}

// MARK: - Helper Components

/// Source button styled like SettingsRowContent
struct UploadSourceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.linkBlue)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(AppColors.settingsRow)
            .cornerRadius(10)
        }
    }
}

/// Compact picker for side-by-side layout
struct UploadCompactPicker: View {
    let label: String
    let value: String?
    let placeholder: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))

            Button(action: action) {
                HStack {
                    Text(value ?? placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(value != nil ? .white : .white.opacity(0.5))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.settingsRow)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Portrait - Enter Details") {
    UploadPage()
        .environment(AppState())
        .modelContainer(for: [CapturedAircraft.self, ICAOLookup.self, AirlineLookup.self])
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        Text("Upload - Landscape")
            .foregroundStyle(.white)
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        Text("Upload - Landscape")
            .foregroundStyle(.white)
    }
    .environment(AppState())
}
