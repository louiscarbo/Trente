//
//  CloudSyncMonitor.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import CloudKit
import CoreData
import Foundation
import Observation

@MainActor
@Observable
final class CloudSyncMonitor {
    static let shared = CloudSyncMonitor()
    static let containerIdentifier = "iCloud.louiscarboestaque.Trente"

    private(set) var accountStatus: CKAccountStatus?
    private(set) var lastSyncDate: Date?
    private(set) var didFinishImport = false
    private var issues: [NSPersistentCloudKitContainer.EventType: CloudSyncIssue] = [:]
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    private init() {}

    var status: CloudSyncStatus {
        CloudSyncStatus.status(
            isSignedIn: accountStatus != .noAccount && accountStatus != .restricted,
            lastSyncDate: lastSyncDate,
            issue: issues.values.first
        )
    }

    func start() {
        guard observers.isEmpty else { return }
        observers = [
            NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: nil,
                queue: .main
            ) { notification in
                let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
                guard let event, event.endDate != nil else { return }
                MainActor.assumeIsolated {
                    CloudSyncMonitor.shared.record(event)
                }
            },
            NotificationCenter.default.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated {
                    CloudSyncMonitor.shared.refreshAccountStatus()
                }
            }
        ]
        refreshAccountStatus()
    }

    private func refreshAccountStatus() {
        Task {
            accountStatus = try? await CKContainer(identifier: Self.containerIdentifier).accountStatus()
        }
    }

    private func record(_ event: NSPersistentCloudKitContainer.Event) {
        if event.type == .import {
            didFinishImport = true
        }
        if event.succeeded {
            issues[event.type] = nil
            if event.type != .setup {
                lastSyncDate = event.endDate
            }
        } else if let error = event.error, let issue = CloudSyncIssue(error: error) {
            issues[event.type] = issue
        }
    }
}
