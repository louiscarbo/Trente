//
//  OnboardingStep.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case budget
    case split
    case notifications
    case applePay
    case allSet

    @MainActor
    static var availableSteps: [OnboardingStep] {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return allCases
        }
        #endif
        return allCases.filter { $0 != .applePay }
    }
}
