//
//  TrentePlusStatus.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Observation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class TrentePlusStatus {
    static let shared = TrentePlusStatus()

    private(set) var hasActiveSubscription = TrentePlusEntitlement.cached() {
        didSet {
            if hasActiveSubscription != oldValue { statusDidChange() }
        }
    }
    @ObservationIgnored private var endDate: Date? {
        didSet {
            if endDate != oldValue { statusDidChange() }
        }
    }
    @ObservationIgnored private var updateTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var initialRefresh: Task<Void, Never>?

    #if DEBUG
    var debugOverride = TrentePlusDebugOverride.stored() {
        didSet {
            debugOverride.store()
            statusDidChange()
        }
    }
    #endif

    private init() {}

    var isSubscribed: Bool {
        #if DEBUG
        debugOverride.isSubscribed(hasActiveSubscription: hasActiveSubscription)
        #else
        hasActiveSubscription
        #endif
    }

    var automaticUnlockedUntil: Date {
        guard isSubscribed else { return .distantPast }
        #if DEBUG
        if debugOverride == .subscribed { return .distantFuture }
        #endif
        return endDate ?? .distantFuture
    }

    func start() {
        guard updateTasks.isEmpty else { return }
        let initialRefresh = Task { await refresh() }
        self.initialRefresh = initialRefresh
        updateTasks = [
            Task {
                await initialRefresh.value
                for await _ in Product.SubscriptionInfo.Status.updates {
                    await refresh()
                }
            },
            Task {
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    await refresh()
                }
            }
        ]
    }

    func refresh() async {
        guard let statuses = try? await Product.SubscriptionInfo.status(for: TrentePlus.groupID) else { return }
        let activeStatuses = statuses.filter { status in TrentePlus.isActive([status.state]) }
        hasActiveSubscription = !activeStatuses.isEmpty
        endDate = TrentePlus.endDate(of: activeStatuses.map(Self.renewal))
    }

    func currentStatus() async -> Bool {
        await initialRefresh?.value
        return isSubscribed
    }

    func currentAutomaticUnlockedUntil() async -> Date {
        await initialRefresh?.value
        return automaticUnlockedUntil
    }

    private static func renewal(of status: Product.SubscriptionInfo.Status) -> (willAutoRenew: Bool, expirationDate: Date?) {
        guard case .verified(let renewalInfo) = status.renewalInfo,
              case .verified(let transaction) = status.transaction
        else { return (true, nil) }
        return (renewalInfo.willAutoRenew, transaction.expirationDate)
    }

    private func statusDidChange() {
        TrentePlusEntitlement.cache(isSubscribed)
        NotificationCenter.default.post(name: TrentePlusEntitlement.didChange, object: nil)
    }
}

extension EnvironmentValues {
    @Entry var isTrentePlusSubscribed = false
}

#if DEBUG
enum TrentePlusDebugOverride: String, CaseIterable {
    case appStore
    case subscribed
    case notSubscribed

    static let key = "debug.trentePlusOverride"

    static func stored(in defaults: UserDefaults = .standard) -> TrentePlusDebugOverride {
        defaults.string(forKey: key).flatMap(TrentePlusDebugOverride.init(rawValue:)) ?? .appStore
    }

    func store(in defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.key)
    }

    func isSubscribed(hasActiveSubscription: Bool) -> Bool {
        switch self {
        case .appStore: hasActiveSubscription
        case .subscribed: true
        case .notSubscribed: false
        }
    }
}
#endif
