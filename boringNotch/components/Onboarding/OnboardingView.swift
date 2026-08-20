//
//  OnboardingView.swift
//  boringNotch
//
//  Created by Alexander on 2025-06-23.
//

import SwiftUI
import Defaults
import Sparkle

enum OnboardingStep {
    case welcome
    case audioCapturePermission
    case musicPermission
    case softwareUpdatePermission
    case finished
}

struct OnboardingView: View {
    @State var step: OnboardingStep = .welcome
    let updater: SPUUpdater?
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        if #available(macOS 14.2, *) {
                            step = .audioCapturePermission
                        } else {
                            step = .musicPermission
                        }
                    }
                }
                .transition(.opacity)

            case .audioCapturePermission:
                PermissionRequestView(
                    icon: Image(systemName: "waveform"),
                    title: "Enable Real-Time Audio",
                    description: "Boring Notch can analyze the audio playing from your music app to draw a live FFT waveform in the notch, with only a minimal impact on CPU usage.",
                    privacyNote: "Audio is processed locally for the visualizer and never recorded, stored, or shared.",
                    onAllow: {
                        Task {
                            let granted = await requestAudioCapturePermission()
                            if granted {
                                Defaults[.realtimeAudioWaveform] = true
                            }
                            withAnimation(.easeInOut(duration: 0.6)) {
                                step = .musicPermission
                            }
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            step = .musicPermission
                        }
                    }
                )
                .transition(.opacity)
                
            case .musicPermission:
                MusicControllerSelectionView(
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            if BoringViewCoordinator.shared.firstLaunch {
                                step = .softwareUpdatePermission
                            } else {
                                step = .finished
                            }
                        }
                    }
                )
                .transition(.opacity)

            case .softwareUpdatePermission:
                SoftwareUpdatePermissionView(
                    updater: updater,
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            BoringViewCoordinator.shared.firstLaunch = false
                            step = .finished
                        }
                    }
                )
                .transition(.opacity)

            case .finished:
                OnboardingFinishView(onFinish: onFinish)
            }
        }
        .frame(width: 400, height: 600)
    }

    func requestAudioCapturePermission() async -> Bool {
        await AudioCaptureManager.shared.requestAudioCapturePermission()
    }
}

struct SoftwareUpdatePermissionView: View {
    let updater: SPUUpdater?
    let onContinue: () -> Void

    @State private var automaticallyChecksForUpdates = true
    @State private var automaticallyDownloadsUpdates = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.effectiveAccent)

            Text("Keep Boring Notch Updated")
                .font(.title)
                .fontWeight(.semibold)

            Text("Boring Notch can check for updates in the background. You can still check manually from the menu bar at any time.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 34)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Check for updates automatically", isOn: $automaticallyChecksForUpdates)

                Toggle("Download and install updates automatically", isOn: $automaticallyDownloadsUpdates)
                    .disabled(!automaticallyChecksForUpdates)
                    .opacity(automaticallyChecksForUpdates ? 1 : 0.45)
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 44)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Continue") {
                applyUpdatePreference(
                    checksAutomatically: automaticallyChecksForUpdates,
                    downloadsAutomatically: automaticallyChecksForUpdates && automaticallyDownloadsUpdates
                )
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .onChange(of: automaticallyChecksForUpdates) { _, enabled in
            if !enabled {
                automaticallyDownloadsUpdates = false
            }
        }
    }

    private func applyUpdatePreference(checksAutomatically: Bool, downloadsAutomatically: Bool) {
        guard let updater else {
            UserDefaults.standard.set(checksAutomatically, forKey: "SUEnableAutomaticChecks")
            UserDefaults.standard.set(downloadsAutomatically, forKey: "SUAutomaticallyUpdate")
            return
        }

        updater.automaticallyChecksForUpdates = checksAutomatically
        updater.automaticallyDownloadsUpdates = downloadsAutomatically
    }
}
