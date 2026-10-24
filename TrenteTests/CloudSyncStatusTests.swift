//
//  CloudSyncStatusTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct CloudSyncStatusTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Without an iCloud account, sync is off whatever happened before")
    func signedOut() {
        #expect(CloudSyncStatus.status(isSignedIn: false, lastSyncDate: date, lastErrorDescription: nil) == .signedOut)
    }

    @Test("Signed in with no sync yet, sync is waiting")
    func waiting() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: nil, lastErrorDescription: nil) == .waiting)
    }

    @Test("A successful sync shows its date")
    func synced() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: date, lastErrorDescription: nil) == .synced(date))
    }

    @Test("The latest error wins over an older success")
    func failed() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: date, lastErrorDescription: "Quota") == .failed("Quota"))
    }
}
