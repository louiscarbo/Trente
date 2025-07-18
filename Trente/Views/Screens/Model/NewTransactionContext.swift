//
//  NewTransactionContext.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 18/07/2025.
//

import SwiftData

struct NewTransactionContext: Codable, Hashable {
    let currency: Currency
    let monthID: PersistentIdentifier
}
