//
//  UploadPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/18/26.
//

import SwiftUI

// MARK: - Upload Page
/// Upload view for selecting existing photos to identify aircraft
struct UploadPage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        OrientationAwarePage(
            portrait: {
                VStack(spacing: 20) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Upload")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Select a photo from your library to identify aircraft")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            },
            leftHorizontal: {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Upload")
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
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Upload")
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
    UploadPage()
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Upload")
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
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
            Text("Upload")
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
