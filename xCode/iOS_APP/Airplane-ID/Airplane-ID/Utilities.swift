//
//  Utilities.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/17/26.
//
//  Shared utility code used across multiple files.
//

import Foundation

// MARK: - CSV Parsing Utilities

/// Parsed aircraft data from CSV - Sendable for safe transfer between threads
struct ParsedAircraftData: Sendable {
    let captureDate: Date
    let longitude: Double
    let latitude: Double
    let year: Int?
    let month: Int?
    let day: Int?
    let icao: String?
    let manufacturer: String?
    let model: String?
    let engineType: Int?
    let engineCount: Int?
    let registration: String?
    let aircraftType: String?
    let aircraftClassification: Int?
    let rating: Double?
    let thumbsUp: Bool?
}

/// Thread-safe CSV parsing utility - nonisolated for use from any actor
enum CSVParser: Sendable {
    nonisolated static func parseLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else { current.append(char) }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}

/// Error type for CSV import operations
enum CSVImportError: Error, LocalizedError {
    case fileNotFound
    case emptyFile
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "CSV file not found"
        case .emptyFile: return "CSV file is empty"
        case .parseError(let message): return message
        }
    }
}
