//
//  WelcomeBackView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import SwiftData
import SwiftUI

struct WelcomeBackView: View {
    let onContinue: () -> Void

    @Query private var months: [Month]
    @Query private var transactions: [TransactionGroup]

    var body: some View {
        WelcomeBackStepView(
            monthCount: months.count,
            transactionCount: transactions.count,
            onContinue: onContinue
        )
    }
}
