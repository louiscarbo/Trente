//
//  SelectCategoryIntent.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import AppIntents

struct SelectCategoryIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Category"
    static let description = IntentDescription("Select a category for the widget.")

    @Parameter(title: "Category")
    var category: WidgetBudgetCategory?
}

struct WidgetBudgetCategory: AppEntity {
    var budgetCategory: BudgetCategory
    var id: String { budgetCategory.rawValue }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Budget Category"
    static let defaultQuery = WidgetBudgetCategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        BudgetCategory.caseDisplayRepresentations[budgetCategory] ?? DisplayRepresentation(title: "\(budgetCategory.name)")
    }

    static let allCategories = BudgetCategory.allCases.map(WidgetBudgetCategory.init)

    static let needs = WidgetBudgetCategory(budgetCategory: .needs)
}

struct WidgetBudgetCategoryQuery: EntityQuery {
    func entities(for identifiers: [WidgetBudgetCategory.ID]) async throws -> [WidgetBudgetCategory] {
        WidgetBudgetCategory.allCategories.filter { identifiers.contains($0.id) }
    }

    func defaultResult() async -> DefaultValue? {
        return WidgetBudgetCategory.allCategories.first
    }

    func suggestedEntities() async throws -> some ResultsCollection {
        return WidgetBudgetCategory.allCategories
    }
}
