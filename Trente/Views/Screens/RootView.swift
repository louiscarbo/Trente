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

    var body: some View {
        Group {
            switch isShowingOnboarding {
            case .none:
                Color.clear
            case .some(true):
                OnboardingView(isFirstLaunch: isFirstLaunch, onFinish: finishOnboarding)
            case .some(false):
                MonthListView()
            }
        }
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
