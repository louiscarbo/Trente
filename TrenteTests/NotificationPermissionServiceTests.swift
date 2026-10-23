//
//  NotificationPermissionServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Testing
import UserNotifications
@testable import Trente

struct NotificationPermissionServiceTests {

    @Test(
        "The system status maps to not asked, authorized or denied",
        arguments: [
            (UNAuthorizationStatus.notDetermined, NotificationPermissionStatus.notDetermined),
            (.authorized, .authorized),
            (.provisional, .authorized),
            (.denied, .denied)
        ]
    )
    func status(systemStatus: UNAuthorizationStatus, expected: NotificationPermissionStatus) async {
        let service = NotificationPermissionService(center: FakeNotificationCenter(status: systemStatus, grants: true))

        #expect(await service.status() == expected)
    }

    @Test("Asking when not asked yet returns the user's answer", arguments: [true, false])
    func requestWhenNotAsked(grants: Bool) async {
        let center = FakeNotificationCenter(status: .notDetermined, grants: grants)
        let service = NotificationPermissionService(center: center)

        let status = await service.requestIfNeeded()

        #expect(status == (grants ? .authorized : .denied))
        #expect(await center.requestCount == 1)
    }

    @Test("A previous answer is never asked again", arguments: [UNAuthorizationStatus.authorized, .denied])
    func noRequestWhenAlreadyAnswered(systemStatus: UNAuthorizationStatus) async {
        let center = FakeNotificationCenter(status: systemStatus, grants: true)
        let service = NotificationPermissionService(center: center)

        _ = await service.requestIfNeeded()

        #expect(await center.requestCount == 0)
    }
}

private actor FakeNotificationCenter: NotificationAuthorizing {
    let status: UNAuthorizationStatus
    let grants: Bool
    private(set) var requestCount = 0

    init(status: UNAuthorizationStatus, grants: Bool) {
        self.status = status
        self.grants = grants
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestCount += 1
        return grants
    }
}
