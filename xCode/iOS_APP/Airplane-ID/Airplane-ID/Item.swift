//
//  Item.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import Foundation
import SwiftData

// MARK: - User Model
/// Represents the app user with account and preferences
/// Note: memberNumber and email are key lookup fields for server sync and login
@Model
final class User {
    var memberNumber: String = ""  // Primary key for server sync
    var name: String
    var email: String
    var phone: String?
    var passwordHash: String?
    var passwordRequired: Bool
    var faceIDEnabled: Bool
    var displayName: String
    var memberDate: Date
    var homeAirport: String?
    var memberLevel: String
    var lastSyncDate: Date?
    var syncToken: String?

    // Privacy preferences (all default to true/on)
    var showOnlineStatus: Bool = true
    var showLocation: Bool = true
    var receiveNews: Bool = true
    var receiveUpdates: Bool = true
    var receiveActivitySummary: Bool = true
    var allowFollow: Bool = true
    var showInSearch: Bool = true

    init(
        memberNumber: String = "",
        name: String,
        email: String,
        phone: String? = nil,
        passwordHash: String? = nil,
        passwordRequired: Bool = false,
        faceIDEnabled: Bool = false,
        displayName: String,
        memberDate: Date = Date(),
        homeAirport: String? = nil,
        memberLevel: String = "free",
        lastSyncDate: Date? = nil,
        syncToken: String? = nil,
        showOnlineStatus: Bool = true,
        showLocation: Bool = true,
        receiveNews: Bool = true,
        receiveUpdates: Bool = true,
        receiveActivitySummary: Bool = true,
        allowFollow: Bool = true,
        showInSearch: Bool = true
    ) {
        self.memberNumber = memberNumber
        self.name = name
        self.email = email
        self.phone = phone
        self.passwordHash = passwordHash
        self.passwordRequired = passwordRequired
        self.faceIDEnabled = faceIDEnabled
        self.displayName = displayName
        self.memberDate = memberDate
        self.homeAirport = homeAirport
        self.memberLevel = memberLevel
        self.lastSyncDate = lastSyncDate
        self.syncToken = syncToken
        self.showOnlineStatus = showOnlineStatus
        self.showLocation = showLocation
        self.receiveNews = receiveNews
        self.receiveUpdates = receiveUpdates
        self.receiveActivitySummary = receiveActivitySummary
        self.allowFollow = allowFollow
        self.showInSearch = showInSearch
    }
}

// MARK: - CapturedAircraft Model
/// Represents an aircraft that has been captured/identified by the user
/// Key fields: captureDate (sorting), icao (unique types), registration (search)
@Model
final class CapturedAircraft: Identifiable {
    // Capture metadata (required at save - from device)
    var captureTime: Date              // Full timestamp when photo taken/uploaded
    var captureDate: Date              // Date only (derived from captureTime)
    var year: Int                      // Derived from captureTime (for filtering)
    var month: Int                     // Derived from captureTime (for filtering)
    var day: Int                       // Derived from captureTime (for filtering)
    var gpsLongitude: Double           // Photo location (where captured)
    var gpsLatitude: Double            // Photo location (where captured)
    var gpsLongitudeNow: Double?       // Current aircraft location (for map, future)
    var gpsLatitudeNow: Double?        // Current aircraft location (for map, future)
    var iPhotoReference: String        // PHAsset.localIdentifier for full-size photo in Photos library
    var thumbnailData: Data?           // Cached JPEG thumbnail (1280x720, 16:9 HD, ~100-200KB)

    // Aircraft identification (required at save - from AI recognition)
    var icao: String                   // ICAO aircraft type code
    var manufacturer: String           // Aircraft manufacturer
    var model: String                  // Aircraft model name

    // Aircraft identification (optional - if AI detects in photo)
    var airlineCode: String?           // 3-letter airline code from AirlineLookup table
    var registration: String?          // N-number / tail number (if visible in photo)

    // Aircraft specifications (optional - populated via cloud sync from FAA data)
    var serialNumber: String?          // Aircraft serial number
    var yearMfg: Int?                  // Year manufactured
    var aircraftCategoryCode: Int?     // FAA category: 1=Land, 2=Sea, 3=Amphibian
    var aircraftClassification: Int?   // Aircraft classification (1-9, see AircraftLookup)
    var aircraftType: String?          // Aircraft type code (1-9, H, O - see AircraftLookup)
    var engineType: Int?               // FAA TYPE-ENG: 0=None, 1=Recip, 2=Turbo-prop, 3=Turbo-shaft, 4=Turbo-jet, 9=Unknown, 10=Electric
    var engineCount: Int?              // Number of engines
    var seatCount: Int?                // Number of seats
    var weightClass: String?           // Weight class

    // Registration/certification details (optional - populated via cloud sync)
    var country: String?               // Country of registration
    var airworthinessDate: Date?       // Airworthiness certificate date
    var certificateIssueDate: Date?    // Certificate issue date
    var certificateExpireDate: Date?   // Certificate expiration date
    var ownerType: String?             // Owner type (individual, corporate, etc.)

    // Registered owner info (optional - populated via cloud sync)
    var registeredOwner: String?       // Owner name
    var registeredAddress1: String?    // Owner address line 1
    var registeredAddress2: String?    // Owner address line 2
    var registeredCity: String?        // Owner city
    var registeredState: String?       // Owner state
    var registeredZip: String?         // Owner zip code

    // User interaction (optional - null unless user acts)
    var rating: Double?                // User star rating (0.5 to 5.0 in 0.5 increments)
    var thumbsUp: Bool?                // User like/dislike for AI training (not shown in UI)

    init(
        // Required - from device at capture
        captureTime: Date,
        captureDate: Date,
        year: Int,
        month: Int,
        day: Int,
        gpsLongitude: Double,
        gpsLatitude: Double,
        gpsLongitudeNow: Double? = nil,
        gpsLatitudeNow: Double? = nil,
        iPhotoReference: String,
        thumbnailData: Data? = nil,
        // Required - from AI recognition
        icao: String,
        manufacturer: String,
        model: String,
        // Optional - if AI detects in photo
        airlineCode: String? = nil,
        registration: String? = nil,
        // Optional - populated via cloud sync
        serialNumber: String? = nil,
        yearMfg: Int? = nil,
        aircraftCategoryCode: Int? = nil,
        aircraftClassification: Int? = nil,
        aircraftType: String? = nil,
        engineType: Int? = nil,
        engineCount: Int? = nil,
        seatCount: Int? = nil,
        weightClass: String? = nil,
        country: String? = nil,
        airworthinessDate: Date? = nil,
        certificateIssueDate: Date? = nil,
        certificateExpireDate: Date? = nil,
        ownerType: String? = nil,
        registeredOwner: String? = nil,
        registeredAddress1: String? = nil,
        registeredAddress2: String? = nil,
        registeredCity: String? = nil,
        registeredState: String? = nil,
        registeredZip: String? = nil,
        // Optional - user interaction
        rating: Double? = nil,
        thumbsUp: Bool? = nil
    ) {
        self.captureTime = captureTime
        self.captureDate = captureDate
        self.year = year
        self.month = month
        self.day = day
        self.gpsLongitude = gpsLongitude
        self.gpsLatitude = gpsLatitude
        self.gpsLongitudeNow = gpsLongitudeNow
        self.gpsLatitudeNow = gpsLatitudeNow
        self.iPhotoReference = iPhotoReference
        self.thumbnailData = thumbnailData
        self.icao = icao
        self.manufacturer = manufacturer
        self.model = model
        self.airlineCode = airlineCode
        self.registration = registration
        self.serialNumber = serialNumber
        self.yearMfg = yearMfg
        self.aircraftCategoryCode = aircraftCategoryCode
        self.aircraftClassification = aircraftClassification
        self.aircraftType = aircraftType
        self.engineType = engineType
        self.engineCount = engineCount
        self.seatCount = seatCount
        self.weightClass = weightClass
        self.country = country
        self.airworthinessDate = airworthinessDate
        self.certificateIssueDate = certificateIssueDate
        self.certificateExpireDate = certificateExpireDate
        self.ownerType = ownerType
        self.registeredOwner = registeredOwner
        self.registeredAddress1 = registeredAddress1
        self.registeredAddress2 = registeredAddress2
        self.registeredCity = registeredCity
        self.registeredState = registeredState
        self.registeredZip = registeredZip
        self.rating = rating
        self.thumbsUp = thumbsUp
    }
}

// MARK: - AirlineLookup Model
/// Reference table for airline codes (separate from aircraft data)
/// Data source: airlinecodes.info
@Model
final class AirlineLookup {
    @Attribute(.unique) var airlineCode: String  // 3-letter airline code (primary key)
    var iata: String?                             // 2-letter IATA code (may be nil)
    var airlineName: String                       // Full airline name

    init(airlineCode: String, iata: String? = nil, airlineName: String) {
        self.airlineCode = airlineCode
        self.iata = iata
        self.airlineName = airlineName
    }
}

// MARK: - ICAOLookup Model
/// Reference table for ICAO aircraft type codes
/// Data source: ICAO Doc 8643 (via PlaneFinder ICAOList.csv)
/// Provides manufacturer, model, and specs for ~2,757 aircraft types
/// Fields mapped to FAA codes for consistency with FAA data imports
@Model
final class ICAOLookup {
    @Attribute(.unique) var icao: String   // ICAO type designator (e.g., "A320", "B738", "C172")
    var manufacturer: String                // Aircraft manufacturer (e.g., "AIRBUS", "BOEING")
    var model: String                       // Aircraft model (e.g., "A-320", "737-800")
    var icaoClass: String                   // Original ICAO class: LandPlane, Helicopter, Amphibian, Gyrocopter, SeaPlane, Tiltrotor
    var aircraftCategoryCode: Int           // FAA category: 1=Land, 2=Sea, 3=Amphibian
    var aircraftType: String                // FAA TYPE-ACFT: "1"=Glider, "4"=FW Single, "5"=FW Multi, "6"=Rotorcraft, "9"=Gyroplane, "H"=Hybrid
    var engineCount: Int                    // Number of engines
    var engineType: Int                     // FAA TYPE-ENG: 0=None, 1=Recip, 2=Turbo-prop, 3=Turbo-shaft, 4=Turbo-jet, 9=Unknown, 10=Electric

    init(
        icao: String,
        manufacturer: String,
        model: String,
        icaoClass: String,
        aircraftCategoryCode: Int,
        aircraftType: String,
        engineCount: Int,
        engineType: Int
    ) {
        self.icao = icao
        self.manufacturer = manufacturer
        self.model = model
        self.icaoClass = icaoClass
        self.aircraftCategoryCode = aircraftCategoryCode
        self.aircraftType = aircraftType
        self.engineCount = engineCount
        self.engineType = engineType
    }
}
