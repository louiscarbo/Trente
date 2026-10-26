//
//  RootView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(OnboardingGate.completedKey) private var hasCompletedOnboarding = false
    @State private var isShowingOnboarding: Bool?
    @State private var isFirstLaunch = false
    @State private var isRestoringFromICloud = false
    @State private var pendingDeepLink: DeepLink?

    var body: some View {
        Group {
            switch isShowingOnboarding {
            case .none:
                Color.clear
            case .some(true) where isRestoringFromICloud:
                ICloudRestoreView(onContinue: finishOnboarding, onNothingFound: startOnboarding)
            case .some(true):
                OnboardingView(isFirstLaunch: isFirstLaunch, onFinish: finishOnboarding)
            case .some(false):
                AppNavigationView(pendingDeepLink: $pendingDeepLink)
            }
        }
        .onOpenURL(perform: handleOpenURL)
        .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        .onAppear(perform: decideOnboarding)
        .onChange(of: hasCompletedOnboarding) { _, isCompleted in
            guard isCompleted else { return }
            withAnimation {
                isShowingOnboarding = false
            }
        }
        #if DEBUG
        .environment(\.replayOnboarding, ReplayOnboardingAction(replay: replayOnboarding))
        #endif
    }

    private func decideOnboarding() {
        guard isShowingOnboarding == nil else { return }
        isFirstLaunch = OnboardingGate.shouldShow(
            hasCompletedOnboarding: hasCompletedOnboarding,
            monthCount: (try? modelContext.fetchCount(FetchDescriptor<Month>())) ?? 0,
            isForced: false
        )
        isShowingOnboarding = isFirstLaunch || OnboardingGate.isForced
        isRestoringFromICloud = isFirstLaunch && TrenteContainer.usesICloudStore
        if isShowingOnboarding == true {
            pendingDeepLink = nil
        }
    }

    private func handleOpenURL(_ url: URL) {
        guard isShowingOnboarding != true, let link = DeepLink(url: url) else { return }
        pendingDeepLink = link
    }

    private func startOnboarding() {
        withAnimation {
            isRestoringFromICloud = false
        }
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        withAnimation {
            isShowingOnboarding = false
        }
    }

    #if DEBUG
    private func replayOnboarding() {
        isFirstLaunch = false
        pendingDeepLink = nil
        withAnimation {
            isShowingOnboarding = true
        }
    }
    #endif
}

#if DEBUG
struct ReplayOnboardingAction: Equatable {
    let replay: () -> Void

    func callAsFunction() {
        replay()
    }

    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

extension EnvironmentValues {
    @Entry var replayOnboarding = ReplayOnboardingAction {}
}
#endif
