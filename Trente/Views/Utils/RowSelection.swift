//
//  RowSelection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import Foundation

struct RowSelection<ID: Hashable> {
    private(set) var isActive = false
    var selectedIDs: Set<ID> = []

    mutating func begin() {
        isActive = true
        selectedIDs = []
    }

    mutating func end() {
        isActive = false
        selectedIDs = []
    }

    mutating func toggle(_ id: ID) {
        if selectedIDs.remove(id) == nil {
            selectedIDs.insert(id)
        }
    }

    mutating func toggleAll(_ visibleIDs: [ID]) {
        selectedIDs = areAllSelected(visibleIDs) ? [] : Set(visibleIDs)
    }

    func areAllSelected(_ visibleIDs: [ID]) -> Bool {
        !visibleIDs.isEmpty && selectedIDs.isSuperset(of: visibleIDs)
    }

    func selectedCount(in visibleIDs: [ID]) -> Int {
        visibleIDs.count { id in selectedIDs.contains(id) }
    }

    func selected<Item: Identifiable>(in items: [Item]) -> [Item] where Item.ID == ID {
        items.filter { item in selectedIDs.contains(item.id) }
    }
}
