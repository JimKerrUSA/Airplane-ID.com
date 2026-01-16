//
//  HomePage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData

struct HomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // Query to fetch the most recent aircraft captures
    @Query(
        sort: \CapturedAircraft.captureDate,
        order: .reverse
    ) private var allAircraft: [CapturedAircraft]

    // Computed property to get the 3 most recent sightings
    private var recentSightings: [CapturedAircraft] {
        Array(allAircraft.prefix(3))
    }

    // Load test data if needed
    private func loadTestDataIfNeeded() {
        print("🏠 HomePage: Checking for test data...")

        // Check if we already have data
        if allAircraft.count > 0 {
            print("ℹ️ Data already exists (\(allAircraft.count) records)")
            return
        }

        print("📥 Loading test data...")

        // Test data from CSV
        let testData: [(icao: String, manufacturer: String, model: String, registration: String, year: Int, month: Int, day: Int, lat: Double, lon: Double)] = [
            ("A500", "Adam", "A-500", "N12345", 2024, 1, 27, 43.99083, -88.57411),
            ("M346", "Aermacchi", "M-346 Master", "N4455", 2024, 2, 8, 43.99056, -88.56877),
            ("M339", "Aermacchi", "MB-339", "N12VS", 2025, 3, 14, 43.98986, -88.56456),
            ("AAT3", "Aero", "3 AT-3", "N3344", 2025, 5, 20, 43.98964, -88.55993),
            ("B701", "Boeing", "707-100", "N1678", 2025, 6, 5, 43.99007, -88.55594),
            ("C172", "Cessna", "Skyhawk", "N2757", 2025, 10, 31, 43.99289, -88.57291),
            ("SR22", "Cirrus", "SR-22", "N252Q", 2025, 12, 24, 43.98845, -88.55797),
            ("S22T", "Cirrus", "SR22 Turbo", "N7779", 2026, 1, 5, 43.98959, -88.55556),
            ("DC3", "Douglas", "DC-3", "N1573", 2026, 1, 5, 43.99073, -88.55169),
            ("ACAM", "Lockwood", "Air Cam", "N79QF", 2026, 1, 7, 43.9879, -88.55548),
            ("HDJT", "Honda", "HondaJet", "N769F", 2026, 1, 15, 43.98968, -88.55128)
        ]

        for data in testData {
            var dateComponents = DateComponents()
            dateComponents.year = data.year
            dateComponents.month = data.month
            dateComponents.day = data.day
            dateComponents.hour = 20
            dateComponents.minute = 9
            dateComponents.second = 45
            dateComponents.timeZone = TimeZone(identifier: "UTC")

            guard let captureDate = Calendar.current.date(from: dateComponents) else { continue }

            let aircraft = CapturedAircraft(
                captureDate: captureDate,
                gpsLongitude: data.lon,
                gpsLatitude: data.lat,
                year: data.year,
                month: data.month,
                day: data.day,
                icao: data.icao,
                manufacturer: data.manufacturer,
                model: data.model,
                registration: data.registration
            )

            modelContext.insert(aircraft)
        }

        do {
            try modelContext.save()
            print("✅ Loaded 11 test aircraft")
        } catch {
            print("❌ Error saving: \(error)")
        }
    }

    // Helper function to format numbers with commas
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    var body: some View {
        OrientationAwarePage(
            portrait: {
                // Portrait version content
                VStack(spacing: 0) {
                    // Empty view to trigger onAppear
                    Color.clear
                        .frame(height: 0)
                        .onAppear {
                            loadTestDataIfNeeded()
                        }
                    // Top data boxes row
                    HStack(spacing: 0) {
                        // Left box - Dark blue with rounded top-left and bottom-left corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("Total")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Aircraft")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Found")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                            }
                        }
                        .frame(width: 125, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                        
                        // Right box - White with rounded top-right and bottom-right corners
                        ZStack {
                            Color(hex: "FFFFFF")
                            
                            Text(formatNumber(appState.totalAircraftCount))
                                .font(.system(size: 40, weight: .regular, design: .default))
                                .foregroundStyle(Color(hex: "FBBD1C"))
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .frame(width: 222, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below top menu
                    
                    // Second data box row
                    HStack(spacing: 0) {
                        // Left box - Dark blue with rounded top-left and bottom-left corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("Total")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Aircraft")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Types")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                            }
                        }
                        .frame(width: 125, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                        
                        // Right box - White with rounded top-right and bottom-right corners
                        ZStack {
                            Color(hex: "FFFFFF")
                            
                            Text(formatNumber(appState.totalTypes))
                                .font(.system(size: 40, weight: .regular, design: .default))
                                .foregroundStyle(Color(hex: "FBBD1C"))
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .frame(width: 222, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below first box
                    
                    // Progress to ACE box
                    VStack(spacing: 0) {
                        // Top section - Dark blue header with rounded top corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            Text("Progress to ACE")
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 347, height: 39)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                        
                        // Bottom section - White with blue border and rounded bottom corners
                        ZStack {
                            Color(hex: "FFFFFF")
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background (incomplete portion)
                                    Rectangle()
                                        .fill(Color(hex: "B9C6D1"))
                                        .frame(width: 313, height: 25)
                                    
                                    // Progress (completed portion)
                                    Rectangle()
                                        .fill(Color(hex: "2B81C5"))
                                        .frame(width: 313 * appState.levelProgress, height: 25)
                                }
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(hex: "000000"), lineWidth: 1)
                                        .frame(width: 313, height: 25)
                                )
                                .frame(width: 313, height: 25)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                        .frame(width: 347, height: 56)
                        .overlay(
                            RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                                .stroke(Color(hex: "124A93"), lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below second box
                    
                    // Bottom box - Recent Sightings
                    VStack(spacing: 0) {
                        // Top section - Dark blue header with rounded top corners
                        ZStack {
                            Color(hex: "082A49")

                            Text("Recent Sightings")
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 347, height: 39)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                        // Bottom section - White with blue border and rounded bottom corners
                        ZStack {
                            Color(hex: "FFFFFF")

                            // Recent sightings list
                            if recentSightings.isEmpty {
                                // Empty state
                                VStack(spacing: 8) {
                                    Image(systemName: "airplane.departure")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                                    Text("No sightings yet")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundStyle(Color(hex: "082A49").opacity(0.6))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(recentSightings) { aircraft in
                                        HStack(alignment: .center, spacing: 10) {
                                            // Airplane icon - centered vertically with text
                                            Image(systemName: "airplane")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Color(hex: "F27C31"))

                                            // Manufacturer and Registration/Model stacked
                                            VStack(alignment: .leading, spacing: 2) {
                                                // Line 1: Manufacturer in ALL CAPS, SF Pro Regular 23pt
                                                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                                    .font(.system(size: 23, weight: .regular))
                                                    .foregroundStyle(Color(hex: "082A49"))

                                                // Line 2: Registration (CAPS) + Model (Title Case), SF Pro Regular 19pt
                                                if let registration = aircraft.registration, !registration.isEmpty {
                                                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                        .font(.system(size: 19, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                } else {
                                                    Text(aircraft.model ?? "")
                                                        .font(.system(size: 19, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                }
                                            }
                                            .padding(.leading, 3) // Move text 3px right
                                        }
                                    }
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width: 347, height: 211)
                        .overlay(
                            RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                                .stroke(Color(hex: "124A93"), lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below progress box
                    
                    Spacer()
                }
            },
            leftHorizontal: {
                // Left horizontal version content
                VStack {
                    Text("HOME - Left Landscape")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            },
            rightHorizontal: {
                // Right horizontal version content
                VStack {
                    Text("HOME - Right Landscape")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        )
    }
}

#Preview {
    HomePage()
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
        .environment(AppState())
}
