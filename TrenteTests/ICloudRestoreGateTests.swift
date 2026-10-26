//
//  ICloudRestoreGateTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import CloudKit
import Testing
@testable import Trente

struct ICloudRestoreGateTests {
    @Test("Months found in iCloud welcome the user back, even before the download finishes")
    func welcomeBack() {
        #expect(ICloudRestoreGate.decision(accountStatus: .available, didFinishImport: false, monthCount: 3) == .welcomeBack)
    }

    @Test("Keeps searching while the account is unknown or the download is still running")
    func searching() {
        #expect(ICloudRestoreGate.decision(accountStatus: nil, didFinishImport: false, monthCount: 0) == .searching)
        #expect(ICloudRestoreGate.decision(accountStatus: .temporarilyUnavailable, didFinishImport: false, monthCount: 0) == .searching)
        #expect(ICloudRestoreGate.decision(accountStatus: .available, didFinishImport: false, monthCount: 0) == .searching)
    }

    @Test("A finished download with no months starts the onboarding")
    func nothingFound() {
        #expect(ICloudRestoreGate.decision(accountStatus: .available, didFinishImport: true, monthCount: 0) == .onboarding)
    }

    @Test("Without a usable iCloud account, the onboarding starts right away", arguments: [CKAccountStatus.noAccount, .restricted, .couldNotDetermine])
    func noAccount(status: CKAccountStatus) {
        #expect(ICloudRestoreGate.decision(accountStatus: status, didFinishImport: false, monthCount: 0) == .onboarding)
    }
}
