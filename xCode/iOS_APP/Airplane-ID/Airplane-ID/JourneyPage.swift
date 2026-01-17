//
//  JourneyPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI

// MARK: - Journey Page
/// User's profile/journey page showing their level, badges, and leaderboard
struct JourneyPage: View {
    @Environment(AppState.self) private var appState

    // Dynamic title based on current status
    private var journeyTitle: String {
        switch appState.status {
        case "NEWBIE": return "Newbie's Journey"
        case "SPOTTER": return "Spotter's Journey"
        case "ENTHUSIAST": return "Enthusiast's Journey"
        case "EXPERT": return "Expert's Journey"
        case "ACE": return "Ace's Journey"
        case "LEGEND": return "Legend's Journey"
        default: return "Your Journey"
        }
    }

    // Level description
    private var levelDescription: String {
        switch appState.status {
        case "NEWBIE": return "You're just getting started! Capture 10 aircraft to become a Spotter."
        case "SPOTTER": return "You've got sharp eyes! Capture 100 aircraft to become an Enthusiast."
        case "ENTHUSIAST": return "You're hooked on aviation! Capture 250 aircraft to become an Expert."
        case "EXPERT": return "Your knowledge is impressive! Capture 500 aircraft to become an Ace."
        case "ACE": return "You're among the elite! Capture 1,100 aircraft to become a Legend."
        case "LEGEND": return "You've reached the pinnacle of aircraft spotting. You are a Legend!"
        default: return "Keep capturing aircraft to level up!"
        }
    }

    var body: some View {
        OrientationAwarePage(
            portrait: {
                VStack(spacing: 24) {
                    // Person icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(AppColors.orange)

                    // Current status
                    Text(appState.status)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(AppColors.gold)

                    // Aircraft count
                    Text("\(appState.totalAircraftCount) Aircraft Captured")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    // Level description
                    Text(levelDescription)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer().frame(height: 20)

                    // Badges section (placeholder)
                    VStack(spacing: 8) {
                        Text("Badges")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Coming Soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    // Leaderboard section (placeholder)
                    VStack(spacing: 8) {
                        Text("Leaderboard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Coming Soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.top, 20)
            },
            leftHorizontal: {
                HStack(spacing: 40) {
                    // Left side - profile info
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppColors.orange)

                        Text(appState.status)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppColors.gold)

                        Text("\(appState.totalAircraftCount) Aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)

                        Text(levelDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    }

                    // Right side - badges & leaderboard
                    VStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Badges")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            Text("Leaderboard")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.leading, 120)
            },
            rightHorizontal: {
                HStack(spacing: 40) {
                    // Left side - badges & leaderboard
                    VStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Badges")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            Text("Leaderboard")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Right side - profile info
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppColors.orange)

                        Text(appState.status)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppColors.gold)

                        Text("\(appState.totalAircraftCount) Aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)

                        Text(levelDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    }
                }
                .padding(.trailing, 120)
            }
        )
    }
}

// MARK: - Preview Helper
/// Creates an AppState with realistic values for previews
private func previewAppState() -> AppState {
    let state = AppState()
    state.status = "SPOTTER"
    state.totalAircraftCount = 11
    state.totalTypes = 11
    return state
}

// MARK: - Previews
#Preview("Portrait") {
    JourneyPage()
        .environment(previewAppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        HStack(spacing: 40) {
            // Left side - profile info
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.orange)

                Text("SPOTTER")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.gold)

                Text("11 Aircraft")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text("You've got sharp eyes! Capture 100 aircraft to become an Enthusiast.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
            }

            // Right side - badges & leaderboard
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Badges")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 4) {
                    Text("Leaderboard")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.leading, 120)
    }
    .environment(previewAppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        HStack(spacing: 40) {
            // Left side - badges & leaderboard
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Badges")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 4) {
                    Text("Leaderboard")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Right side - profile info
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.orange)

                Text("SPOTTER")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.gold)

                Text("11 Aircraft")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text("You've got sharp eyes! Capture 100 aircraft to become an Enthusiast.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
            }
        }
        .padding(.trailing, 120)
    }
    .environment(previewAppState())
}
