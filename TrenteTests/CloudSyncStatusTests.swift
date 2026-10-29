//
//  CloudSyncStatusTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import CloudKit
import Foundation
import Testing
@testable import Trente

struct CloudSyncStatusTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Without an iCloud account, sync is off whatever happened before")
    func signedOut() {
        #expect(CloudSyncStatus.status(isSignedIn: false, lastSyncDate: date, issue: .storageFull) == .signedOut)
    }

    @Test("Signed in with no sync yet, sync is waiting")
    func waiting() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: nil, issue: nil) == .waiting)
    }

    @Test("A successful sync shows its date")
    func synced() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: date, issue: nil) == .synced(date))
    }

    @Test("An issue the user can fix wins over an older success")
    func needsAttention() {
        #expect(CloudSyncStatus.status(isSignedIn: true, lastSyncDate: date, issue: .storageFull) == .needsAttention(.storageFull))
    }

    @Test("Full iCloud storage is an issue the user can fix")
    func quotaExceeded() {
        #expect(CloudSyncIssue(error: CKError(.quotaExceeded)) == .storageFull)
    }

    @Test("A signed out or restricted account is an issue the user can fix", arguments: [CKError.Code.notAuthenticated, .managedAccountRestricted])
    func accountUnavailable(code: CKError.Code) {
        #expect(CloudSyncIssue(error: CKError(code)) == .accountUnavailable)
    }

    @Test("Errors iCloud retries by itself are not shown", arguments: [CKError.Code.networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy])
    func transientErrors(code: CKError.Code) {
        #expect(CloudSyncIssue(error: CKError(code)) == nil)
    }

    @Test("A partial failure is an issue only when one of its items is")
    func partialFailure() {
        let recordID = CKRecord.ID(recordName: "month")
        let full = CKError(.partialFailure, userInfo: [CKPartialErrorsByItemIDKey: [recordID: CKError(.quotaExceeded)]])
        let busy = CKError(.partialFailure, userInfo: [CKPartialErrorsByItemIDKey: [recordID: CKError(.zoneBusy)]])

        #expect(CloudSyncIssue(error: full) == .storageFull)
        #expect(CloudSyncIssue(error: busy) == nil)
    }

    @Test("Errors outside iCloud are not shown")
    func otherErrors() {
        #expect(CloudSyncIssue(error: CocoaError(.fileReadNoPermission)) == nil)
    }
}
