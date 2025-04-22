//
//  DisplayableTransaction.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import Foundation
import SwiftUI

struct DisplayableTransaction: Identifiable, Equatable {
    static func == (lhs: DisplayableTransaction, rhs: DisplayableTransaction) -> Bool {
        lhs.id == rhs.id
    }
    
    enum Kind {
        case group(TransactionGroup)
        case recurring(RecurringTransactionInstance)
    }
    let id = UUID()
    let kind: Kind
    
    var date: Date {
        switch kind {
        case .group(let g):      return g.addedDate
        case .recurring(let r):  return r.date
        }
    }
    var title: String {
        switch kind {
        case .group(let g):      return g.title
        case .recurring(let r):  return r.rule.title
        }
    }
    var searchableString: String {
        let delimiter = "\u{001F}"
        
        switch kind {
        case .group(let g):
            let title = g.title
            let categories = g.entries.map { $0.category.name }.joined(separator: delimiter)
            let date = g.addedDate.formatted(.dateTime.year().month(.wide).day().weekday(.wide))
            let amount = displayAmount
            return title + delimiter + categories + delimiter + date + delimiter + amount
        case .recurring(let r):
            let title = r.rule.title
            let categories = r.rule.category.name
            let date = r.date.formatted(.dateTime.year().month(.wide).day().weekday(.wide))
            let amount = displayAmount
            return title + delimiter + categories + delimiter + date + delimiter + amount
        }
    }
    var categories: [BudgetCategory] {
        switch kind {
        case .group(let g):
            return g.entries.map { $0.category }
        case .recurring(let r):
            return [r.rule.category]
        }
    }
    var amountCents: Int {
        switch kind {
        case .group(let g):      return g.totalAmountCents
        case .recurring(let r):  return r.rule.amountCents
        }
    }
    var displayAmount: String {
        let code: String
        switch kind {
        case .group(let g):      code = g.month.currency.isoCode
        case .recurring(let r):  code = r.month.currency.isoCode
        }
        return (Double(amountCents)/100).formatted(.currency(code: code))
    }
    var displayDate: String {
        date.formatted(.dateTime.weekday().day().month(.wide).year())
    }
    
    // 2. Vue spécifique pour chaque kind
    @ViewBuilder
    func rowView() -> some View {
        switch kind {
        case .group(let g):      TransactionGroupRowView(transactionGroup: g)
        case .recurring(let r):  RecurringTransactionRowView(recurringTransactionInstance: r)
        }
    }
}
