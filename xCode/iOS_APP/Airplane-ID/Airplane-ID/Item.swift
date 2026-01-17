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
        syncToken: String? = nil
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
    }
}

// MARK: - CapturedAircraft Model
/// Represents an aircraft that has been captured/identified by the user
/// Key fields: captureDate (sorting), icao (unique types), registration (search)
@Model
final class CapturedAircraft {
    var captureDate: Date
    var gpsLongitude: Double
    var gpsLatitude: Double
    var year: Int?
    var month: Int?
    var day: Int?
    var timeUTC: String?
    var iPhotoReference: String?
    var icao: String?
    var manufacturer: String?
    var model: String?
    var engine: String?
    var numberOfEngines: Int?
    var registration: String?
    var rating: Int?
    var thumbsUp: Bool?

    init(
        captureDate: Date,
        gpsLongitude: Double,
        gpsLatitude: Double,
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil,
        timeUTC: String? = nil,
        iPhotoReference: String? = nil,
        icao: String? = nil,
        manufacturer: String? = nil,
        model: String? = nil,
        engine: String? = nil,
        numberOfEngines: Int? = nil,
        registration: String? = nil,
        rating: Int? = nil,
        thumbsUp: Bool? = nil
    ) {
        self.captureDate = captureDate
        self.gpsLongitude = gpsLongitude
        self.gpsLatitude = gpsLatitude
        self.year = year
        self.month = month
        self.day = day
        self.timeUTC = timeUTC
        self.iPhotoReference = iPhotoReference
        self.icao = icao
        self.manufacturer = manufacturer
        self.model = model
        self.engine = engine
        self.numberOfEngines = numberOfEngines
        self.registration = registration
        self.rating = rating
        self.thumbsUp = thumbsUp
    }
}
