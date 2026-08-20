//
//  OnboardingFinishView.swift
//  boringNotch
//
//  Created by Alexander on 2025-06-23.
//

import SwiftUI

struct OnboardingFinishView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.effectiveAccent)
                .padding()

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You can now enjoy the app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()

            Button("Finish", action: onFinish)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    OnboardingFinishView(onFinish: { })
}
