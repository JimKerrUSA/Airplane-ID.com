//
//  Item.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

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
