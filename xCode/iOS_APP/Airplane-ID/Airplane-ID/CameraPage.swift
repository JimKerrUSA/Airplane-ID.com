//
//  CameraPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/16/26.
//

import SwiftUI

// MARK: - Camera Page
/// Camera view for capturing aircraft
struct CameraPage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        OrientationAwarePage(
            portrait: {
                VStack(spacing: 20) {
                    Image(systemName: "camera")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Camera")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Point your camera at an aircraft to identify it")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            },
            leftHorizontal: {
                VStack(spacing: 16) {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Camera")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.leading, 120)
            },
            rightHorizontal: {
                VStack(spacing: 16) {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Camera")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.trailing, 120)
            }
        )
    }
}

// MARK: - Previews
#Preview("Portrait") {
    CameraPage()
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Camera")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Coming Soon")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.leading, 120)
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Camera")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Coming Soon")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.trailing, 120)
    }
    .environment(AppState())
}
