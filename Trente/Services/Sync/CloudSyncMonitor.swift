//
//  CloudSyncMonitor.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import CoreData
import Foundation
import Observation

@MainActor
@Observable
final class CloudSyncMonitor {
    static let shared = CloudSyncMonitor()

    private(set) var lastSyncDate: Date?
    private(set) var lastErrorDescription: String?
    @ObservationIgnored private var observer: (any NSObjectProtocol)?

    private init() {}

    var status: CloudSyncStatus {
        CloudSyncStatus.status(
            isSignedIn: FileManager.default.ubiquityIdentityToken != nil,
            lastSyncDate: lastSyncDate,
            lastErrorDescription: lastErrorDescription
        )
    }

    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event
            guard let event, let endDate = event.endDate else { return }
            let errorDescription = event.succeeded ? nil : event.error?.localizedDescription
            MainActor.assumeIsolated {
                CloudSyncMonitor.shared.record(endDate: endDate, errorDescription: errorDescription)
            }
        }
    }

    private func record(endDate: Date, errorDescription: String?) {
        if let errorDescription {
            lastErrorDescription = errorDescription
        } else {
            lastSyncDate = endDate
            lastErrorDescription = nil
        }
    }
}
