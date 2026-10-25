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
    @State private var notificationPermission = NotificationPermissionState()
    @AppStorage(ReminderTime.hourKey) private var reminderHour = ReminderTime.standard.hour
    @AppStorage(ReminderTime.minuteKey) private var reminderMinute = ReminderTime.standard.minute
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
                    reminderTime: reminderTime,
                    mentionsApplePay: isPhone,
                    onTurnOn: turnOnNotifications,
                    onOpenSettings: openNotificationSettings
                )
                #if os(iOS)
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
                ToolbarItem(placement: .closeButtonPlacement) {
                    Button { dismiss() } label: {
                        Label("Close", systemImage: "chevron.down")
                    }
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
        .refreshesNotificationPermission(notificationPermission)
        #if os(iOS)
        .manageSubscriptionsSheet(
            isPresented: $isShowingManageSubscriptions,
            subscriptionGroupID: TrentePlus.groupID
        )
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

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                ReminderTime(hour: reminderHour, minute: reminderMinute).date(on: .now) ?? .now
            },
            set: { date in
                let time = ReminderTime(date: date)
                reminderHour = time.hour
                reminderMinute = time.minute
            }
        )
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
