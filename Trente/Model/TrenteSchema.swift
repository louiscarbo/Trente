//
//  TrenteSchema.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Month.self,
            TransactionGroup.self,
            TransactionEntry.self,
            RecurringTransactionRule.self,
            RecurringTransactionInstance.self,
            PendingTransaction.self
        ]
    }
}

typealias Month = SchemaV1.Month
typealias TransactionGroup = SchemaV1.TransactionGroup
typealias TransactionEntry = SchemaV1.TransactionEntry
typealias RecurringTransactionRule = SchemaV1.RecurringTransactionRule
typealias RecurringTransactionInstance = SchemaV1.RecurringTransactionInstance
typealias PendingTransaction = SchemaV1.PendingTransaction

enum TrenteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

extension Schema {
    static let trente = Schema(versionedSchema: SchemaV1.self)
}
