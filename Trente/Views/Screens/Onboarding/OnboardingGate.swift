//
//  OnboardingGate.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation

enum OnboardingGate {
    static let completedKey = "hasCompletedOnboarding"
    static let forceArgument = "-showOnboarding"

    static var isForced: Bool {
        ProcessInfo.processInfo.arguments.contains(forceArgument)
    }

    static func shouldShow(hasCompletedOnboarding: Bool, monthCount: Int, isForced: Bool) -> Bool {
        isForced || (!hasCompletedOnboarding && monthCount == 0)
    }
}
