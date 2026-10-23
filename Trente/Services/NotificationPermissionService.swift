//
//  NotificationPermissionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import UserNotifications

enum NotificationPermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

protocol NotificationAuthorizing: Sendable {
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: NotificationAuthorizing {
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

struct NotificationPermissionService {
    private let center: any NotificationAuthorizing

    init(center: any NotificationAuthorizing = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func status() async -> NotificationPermissionStatus {
        switch await center.currentAuthorizationStatus() {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized, .provisional, .ephemeral:
            .authorized
        @unknown default:
            .denied
        }
    }

    func requestIfNeeded() async -> NotificationPermissionStatus {
        guard await status() == .notDetermined else { return await status() }
        let isGranted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        return isGranted ? .authorized : .denied
    }
}
