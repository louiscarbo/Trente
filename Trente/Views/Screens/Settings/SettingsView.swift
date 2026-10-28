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
    @Environment(\.isTrentePlusSubscribed) private var isSubscribed
    @State private var isShowingPaywall = false
    @State private var notificationPermission = NotificationPermissionState()
    @State private var reminderTime = ReminderTime.stored().date(on: .now) ?? .now
    @AppStorage(NotificationPreferences.recurringTransactionsKey) private var remindsRecurringTransactions = true
    @AppStorage(NotificationPreferences.newMonthKey) private var announcesNewMonths = true
    @State private var syncMonitor = CloudSyncMonitor.shared
    #if os(iOS)
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingManageSubscriptions = false
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
                NotificationsSection(
                    status: notificationPermission.status,
                    remindsRecurringTransactions: $remindsRecurringTransactions,
                    announcesNewMonths: $announcesNewMonths,
                    reminderTime: $reminderTime,
                    mentionsApplePay: DeviceIdiom.isPhone,
                    onTurnOn: turnOnNotifications,
                    onOpenSettings: openNotificationSettings
                )
                #if os(iOS)
                if DeviceIdiom.isPhone {
                    ApplePaySection(onGetShortcut: openShortcut)
                }
                #endif
                DataSection(syncStatus: syncMonitor.status)
                HelpAboutSection(
                    faqItems: FAQItem.items(isPhone: DeviceIdiom.isPhone),
                    contactURL: SupportMail.feedbackURL(appInfo: appInfo),
                    contactAddress: SupportMail.address,
                    reviewURL: ExternalLinks.writeReview,
                    privacyPolicyURL: ExternalLinks.privacyPolicy,
                    termsOfUseURL: ExternalLinks.termsOfUse,
                    profile: .louis,
                    credits: CreditSection.all,
                    versionDescription: appInfo.versionDescription
                )
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .inlineNavigationBarTitleDisplayMode()
            #if os(iOS)
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
            #endif
        }
        .sheet(isPresented: $isShowingPaywall) {
            SubscriptionView()
        }
        .refreshesNotificationPermission(notificationPermission)
        .onChange(of: reminderTime) { _, time in
            ReminderTime(date: time).store()
        }
        #if os(iOS)
        .manageSubscriptionsSheet(
            isPresented: $isShowingManageSubscriptions,
            subscriptionGroupID: TrentePlus.groupID
        )
        #elseif os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 520)
        #endif
    }

    private func manageSubscription() {
        #if os(iOS)
        isShowingManageSubscriptions = true
        #else
        openURL(ExternalLinks.manageSubscriptions)
        #endif
    }

    private func turnOnNotifications() {
        Task {
            await notificationPermission.request()
        }
    }

    private func openNotificationSettings() {
        guard let url = ExternalLinks.notificationSettings else { return }
        openURL(url)
    }

    #if os(iOS)
    private func openShortcut() {
        openURL(ExternalLinks.logWalletTransactionShortcut)
    }
    #endif
}

#Preview {
    SettingsView()
}
