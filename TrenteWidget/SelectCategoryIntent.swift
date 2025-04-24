//
//  SelectCategoryIntent.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import AppIntents

struct SelectCategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Category"
    static var description = IntentDescription("Select a category for the widget.")
    
    @Parameter(title: "Category")
    var category: WidgetBudgetCategory?
}

struct WidgetBudgetCategory: AppEntity {
    var id: UUID = UUID()
    var budgetCategory: BudgetCategory
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Budget Category"
    static var defaultQuery = WidgetBudgetCategoryQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(budgetCategory.name)")
    }
    
    static let allCategories: [WidgetBudgetCategory] = {
        let categories = BudgetCategory.allCases
        return categories.map { WidgetBudgetCategory(budgetCategory: $0) }
    }()
    
    static let needs: WidgetBudgetCategory = {
        WidgetBudgetCategory(budgetCategory: BudgetCategory.needs)
    }()
}

struct WidgetBudgetCategoryQuery: EntityQuery {
    func entities(for identifiers: [WidgetBudgetCategory.ID]) async throws -> [WidgetBudgetCategory] {
        return WidgetBudgetCategory.allCategories
    }
    
    func defaultResult() async -> DefaultValue? {
        return WidgetBudgetCategory.allCategories.first
    }
    
    func suggestedEntities() async throws -> some ResultsCollection {
        return WidgetBudgetCategory.allCategories
    }
}
