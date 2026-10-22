# Trente Model Layer

This document explains the relationships between the different data models used in the Trente application, focusing on how transactions are represented.

## Core Transaction Models

The transaction system is composed of four main models: `TransactionGroup`, `TransactionEntry`, `RecurringTransactionRule`, and `RecurringTransactionInstance`.

### `TransactionEntry`

A `TransactionEntry` represents the most granular part of a transaction. It holds a specific amount of money that is either an expense or allocated to a specific budget category in the case of an income. Each `TransactionEntry` is associated with a `BudgetCategory`.

### `TransactionGroup`

A `TransactionGroup` bundles together one or more `TransactionEntry` objects that belong to the same transaction. It contains shared information like the transaction's title, date, and any attached notes or images.

*   **Expense:** An expense transaction will have a single `TransactionGroup` containing a single `TransactionEntry`.
*   **Income:** An income transaction will have a single `TransactionGroup` containing multiple `TransactionEntry` objects, one for each `BudgetCategory` the income is distributed to.

### `RecurringTransactionRule`

A `RecurringTransactionRule` defines a transaction that repeats over time. It stores all the information needed to generate future instances of the transaction, such as:

*   The frequency of the recurrence (e.g., monthly, weekly).
*   The start and end dates for the recurrence.
*   The template for the `TransactionGroup` to be created, including title, amount, and category information.

`repartition: [BudgetCategory: Int]` stores this amount, signed exactly like `TransactionEntry.amountCents` (negative = expense, positive = income). Since an expense always produces a single `TransactionEntry` (see above), an expense rule's `repartition` must contain exactly one category — only income rules are split across multiple categories. UI editing a rule's repartition must branch on this sign rather than reusing the multi-category income split UI for expenses.

### `RecurringTransactionInstance`

A `RecurringTransactionInstance` represents a specific, scheduled occurrence of a `RecurringTransactionRule`. For example, a monthly bill will have a `RecurringTransactionInstance` for each upcoming month. These instances are what get converted into actual `TransactionGroup`s when they are actually added/validated by the user (ie, when they are actually taken into account in the budget, ie when they are paid).

## How They Work Together

1.  When a user creates a **recurring transaction**, a `RecurringTransactionRule` is saved to the database.
2.  The application then generates `RecurringTransactionInstance`s for the upcoming dates based on this rule.
3.  When a `RecurringTransactionInstance`'s date is reached, the user can "validate" it, which transforms it into a `TransactionGroup` with its corresponding `TransactionEntry` objects.
4.  For a **non-recurring transaction**, a `TransactionGroup` and its associated `TransactionEntry` objects are created and saved directly.

This structure allows for a flexible and powerful way to manage both one-time and recurring transactions, while keeping the data normalized and easy to manage.

## Schema Versioning

All `@Model` classes are nested in `SchemaV1` (see `TrenteSchema.swift`) and exposed through top-level typealiases, so the rest of the app refers to `Month`, `TransactionGroup`, etc. `TrenteMigrationPlan` is passed to every `ModelContainer`.

- **Before the first App Store release:** edit the models in `SchemaV1` directly. No new versions, no migration stages. Breaking the store on test devices is acceptable (reinstall).
- **After release:** never modify a shipped `SchemaVn`. Copy the models into `SchemaVn+1`, apply the change there, point the typealiases at the new version, append it to `TrenteMigrationPlan.schemas` and add a `.lightweight` or `.custom` stage. Test upgrading an on-disk store created by the previous version.
- **When freezing a `SchemaVn`:** strip its class bodies down to stored properties and plain inits. Behavior lives in extensions on the typealiases, which follow the current version, so a frozen class must not depend on them.
