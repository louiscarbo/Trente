//
//  NotificationPermissionState.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import SwiftUI

@MainActor
@Observable
final class NotificationPermissionState {
    private(set) var status: NotificationPermissionStatus?

    @ObservationIgnored private let service: NotificationPermissionService

    init(service: NotificationPermissionService = NotificationPermissionService()) {
        self.service = service
    }

    func refresh() async {
        status = await service.status()
    }

    func request() async {
        status = await service.requestIfNeeded()
    }
}

private struct NotificationPermissionRefresh: ViewModifier {
    let permission: NotificationPermissionState

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task {
                await permission.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await permission.refresh() }
            }
    }
}

extension View {
    func refreshesNotificationPermission(_ permission: NotificationPermissionState) -> some View {
        modifier(NotificationPermissionRefresh(permission: permission))
    }
}
