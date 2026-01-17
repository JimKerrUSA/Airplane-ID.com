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
    var iPhotoReference: String        // Link to photo in device iPhoto library

    // Aircraft identification (required at save - from AI recognition)
    var icao: String                   // ICAO aircraft type code
    var manufacturer: String           // Aircraft manufacturer
    var model: String                  // Aircraft model name

    // Aircraft identification (optional - if AI detects in photo)
    var iata: String?                  // IATA airline code (e.g., AA, UA) - airliners only
    var registration: String?          // N-number / tail number (if visible in photo)

    // Aircraft specifications (optional - populated via cloud sync from FAA data)
    var serialNumber: String?          // Aircraft serial number
    var yearMfg: Int?                  // Year manufactured
    var aircraftClassification: Int?   // Aircraft classification (1-9, see AircraftLookup)
    var aircraftType: String?          // Aircraft type code (1-9, H, O - see AircraftLookup)
    var engineType: String?            // Engine type
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
        // Required - from AI recognition
        icao: String,
        manufacturer: String,
        model: String,
        // Optional - if AI detects in photo
        iata: String? = nil,
        registration: String? = nil,
        // Optional - populated via cloud sync
        serialNumber: String? = nil,
        yearMfg: Int? = nil,
        aircraftClassification: Int? = nil,
        aircraftType: String? = nil,
        engineType: String? = nil,
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
        self.icao = icao
        self.manufacturer = manufacturer
        self.model = model
        self.iata = iata
        self.registration = registration
        self.serialNumber = serialNumber
        self.yearMfg = yearMfg
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

// MARK: - AirlineCode Model
/// Reference table for airline ICAO and IATA codes
/// Data source: airlinecodes.info
@Model
final class AirlineCode {
    @Attribute(.unique) var icao: String   // ICAO airline code (3-letter, primary key)
    var iata: String?                       // IATA airline code (2-letter, may be nil)
    var airline: String                     // Airline name

    init(icao: String, iata: String? = nil, airline: String) {
        self.icao = icao
        self.iata = iata
        self.airline = airline
    }
}
