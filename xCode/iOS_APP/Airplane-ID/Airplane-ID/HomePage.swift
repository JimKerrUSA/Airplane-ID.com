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
                                                // Line 1: Manufacturer in ALL CAPS, SF Pro Regular 22pt
                                                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                                    .font(.system(size: 22, weight: .regular))
                                                    .foregroundStyle(Color(hex: "082A49"))

                                                // Line 2: Registration (CAPS) + Model (Title Case), SF Pro Regular 18pt
                                                if let registration = aircraft.registration, !registration.isEmpty {
                                                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                        .font(.system(size: 18, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                } else {
                                                    Text(aircraft.model ?? "")
                                                        .font(.system(size: 18, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                }
                                            }
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
