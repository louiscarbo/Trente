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
    @State private var isShowingWelcomeBack = false
    @State private var pendingDeepLink: DeepLink?
    @State private var trenteVingtExport: TrenteVingtExport?
    @State private var isShowingTrenteVingtImport = false

    var body: some View {
        Group {
            switch isShowingOnboarding {
            case .none:
                Color.clear
            case .some(true) where isShowingWelcomeBack:
                WelcomeBackView(onContinue: finishOnboarding)
            case .some(true) where trenteVingtExport != nil:
                if let trenteVingtExport {
                    TrenteVingtWelcomeView(
                        export: trenteVingtExport,
                        onImported: finishTrenteVingtImport,
                        onStartFresh: startFresh
                    )
                }
            case .some(true):
                OnboardingView(
                    isFirstLaunch: isFirstLaunch,
                    watchesICloud: isFirstLaunch && TrenteContainer.usesICloudStore,
                    onICloudDataFound: showWelcomeBack,
                    onFinish: finishOnboarding
                )
            case .some(false):
                AppNavigationView(pendingDeepLink: $pendingDeepLink)
                    .sheet(isPresented: $isShowingTrenteVingtImport) {
                        NavigationStack {
                            TrenteVingtImportView()
                                .toolbar {
                                    CloseToolbarItem { isShowingTrenteVingtImport = false }
                                }
                        }
                    }
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
        if isShowingOnboarding == true {
            pendingDeepLink = nil
        }
        if isFirstLaunch {
            trenteVingtExport = importableTrenteVingtExport()
        }
    }

    private func importableTrenteVingtExport() -> TrenteVingtExport? {
        guard let export = TrenteVingtSnapshot.load(),
              let summary = try? TrenteVingtImporter().preview(of: export, in: modelContext),
              summary.monthCount > 0
        else { return nil }
        return export
    }

    private func handleOpenURL(_ url: URL) {
        if TrenteVingtSnapshot.isImportURL(url) {
            showTrenteVingtImport()
            return
        }
        guard isShowingOnboarding != true, let link = DeepLink(url: url) else { return }
        pendingDeepLink = link
    }

    private func showTrenteVingtImport() {
        isShowingTrenteVingtImport = true
        guard isShowingOnboarding == true else { return }
        withAnimation {
            trenteVingtExport = importableTrenteVingtExport()
        }
    }

    private func startFresh() {
        isShowingTrenteVingtImport = false
        withAnimation {
            trenteVingtExport = nil
        }
    }

    private func finishTrenteVingtImport() {
        isShowingTrenteVingtImport = false
        finishOnboarding()
    }

    private func showWelcomeBack() {
        withAnimation {
            isShowingWelcomeBack = true
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
