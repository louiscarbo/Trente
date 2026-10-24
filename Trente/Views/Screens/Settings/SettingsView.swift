//
//  SettingsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var isSubscribed = false
    @State private var isShowingPaywall = false
    #if os(iOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: NotificationPermissionStatus?
    @State private var isShowingManageSubscriptions = false

    private let notificationPermission = NotificationPermissionService()
    #endif

    var body: some View {
        let appInfo = AppInfo.current

        NavigationStack {
            Form {
                TrentePlusSection(
                    isSubscribed: isSubscribed,
                    onDiscover: { isShowingPaywall = true },
                    onManage: manageSubscription
                )
                #if os(iOS)
                NotificationsSection(
                    status: notificationStatus,
                    onTurnOn: turnOnNotifications,
                    onOpenSettings: openNotificationSettings
                )
                if isPhone {
                    ApplePaySection(
                        setupSteps: ShortcutsSetupCard.applePaySetupSteps,
                        onGetShortcut: openShortcut
                    )
                }
                #endif
                HelpAboutSection(
                    faqItems: FAQItem.items(isPhone: isPhone),
                    contactURL: SupportMail.feedbackURL(appInfo: appInfo),
                    contactAddress: SupportMail.address,
                    reviewURL: ExternalLinks.writeReview,
                    profile: .louis,
                    credits: CreditSection.all,
                    versionDescription: appInfo.versionDescription
                )
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            #endif
        }
        .subscriptionStatusTask(for: TrentePlus.groupID) { taskState in
            isSubscribed = TrentePlus.isActive((taskState.value ?? []).map(\.state))
        }
        .sheet(isPresented: $isShowingPaywall) {
            SubscriptionView()
        }
        #if os(iOS)
        .manageSubscriptionsSheet(
            isPresented: $isShowingManageSubscriptions,
            subscriptionGroupID: TrentePlus.groupID
        )
        .task {
            await refreshNotificationStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshNotificationStatus() }
        }
        #elseif os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 520)
        #endif
    }

    private var isPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    private func manageSubscription() {
        #if os(iOS)
        isShowingManageSubscriptions = true
        #else
        openURL(ExternalLinks.manageSubscriptions)
        #endif
    }

    #if os(iOS)
    private func refreshNotificationStatus() async {
        notificationStatus = await notificationPermission.status()
    }

    private func turnOnNotifications() {
        Task {
            notificationStatus = await notificationPermission.requestIfNeeded()
        }
    }

    private func openNotificationSettings() {
        guard let url = ExternalLinks.notificationSettings else { return }
        openURL(url)
    }

    private func openShortcut() {
        openURL(ExternalLinks.logWalletTransactionShortcut)
    }
    #endif
}

#Preview {
    SettingsView()
}
