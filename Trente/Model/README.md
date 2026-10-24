# Trente Model Layer

This document explains the relationships between the different data models used in the Trente application, focusing on how transactions are represented.

## Core Transaction Models

The transaction system is composed of three stored models, `TransactionGroup`, `TransactionEntry` and `RecurringTransactionRule`, plus one computed value type, `RecurringTransactionOccurrence`.

### `TransactionEntry`

A `TransactionEntry` represents the most granular part of a transaction. It holds a specific amount of money that is either an expense or allocated to a specific budget category in the case of an income. Each `TransactionEntry` is associated with a `BudgetCategory`.

### `TransactionGroup`

A `TransactionGroup` bundles together one or more `TransactionEntry` objects that belong to the same transaction. It contains shared information like the transaction's title, date, and any attached notes or images.

*   **Expense:** An expense transaction will have a single `TransactionGroup` containing a single `TransactionEntry`.
*   **Income:** An income transaction will have a single `TransactionGroup` containing multiple `TransactionEntry` objects, one for each `BudgetCategory` the income is distributed to.

A group created from a recurring transaction keeps `recurringRule` and `recurringOccurrenceDate`: the rule it came from and the scheduled date it settles. Deleting the rule nullifies the link and keeps the group.

### `RecurringTransactionRule`

A `RecurringTransactionRule` defines a transaction that repeats over time. It is the single source of truth for the schedule and the template:

*   The frequency of the recurrence (weekly, monthly, yearly).
*   The start date (its day is the anchor of the schedule) and optional end date, both inclusive and compared by day.
*   `createdAt`: nothing is ever scheduled before the rule's creation day, so a new rule never touches past budgets.
*   `skippedOccurrenceDates`: occurrences the user chose to skip.
*   `id`: a permanent identifier, so a notification can find its rule again (a `PersistentIdentifier` decoded from a notification isn't reliable).
*   `lastAutoConfirmedDate`: the latest occurrence an automatic rule recorded by itself. Automatic recording only looks after this date, so a deleted automatic transaction comes back as pending instead of being recorded again.
*   The template for the `TransactionGroup` to be created, including title, amount, and category information.

`repartition: [BudgetCategory: Int]` stores this amount, signed exactly like `TransactionEntry.amountCents` (negative = expense, positive = income). Since an expense always produces a single `TransactionEntry` (see above), an expense rule's `repartition` must contain exactly one category — only income rules are split across multiple categories. UI editing a rule's repartition must branch on this sign rather than reusing the multi-category income split UI for expenses.

### `RecurringTransactionOccurrence`

A `RecurringTransactionOccurrence` is one expected payment of a rule on one day, inside one `Month`. It is a plain struct, built from the rule each time a month is displayed, and is never stored.

`RecurrenceSchedule` computes the dates: it anchors on the start day, clamps the 31st to the last day of shorter months (and February 29 to the 28th), and ignores the time of day.

## How They Work Together

1.  When a user creates a **recurring transaction**, only a `RecurringTransactionRule` is saved.
2.  When a month is shown, each rule's schedule produces the occurrences that fall inside the month.
3.  An occurrence is **settled** when one of the rule's transactions has a `recurringOccurrenceDate` in the same period (same week, month or year, depending on the frequency). Settled occurrences are hidden, and so are skipped ones (a skipped date in the same period). Matching by period means moving the payment day doesn't bring back an occurrence already confirmed or skipped that period.
4.  Confirming an occurrence creates the `TransactionGroup` (dated now) and its entries, linked to the rule and the occurrence date. Deleting that group makes the occurrence pending again.
5.  Rules with `autoConfirm` are confirmed by the app when it becomes active, the day changes or data is saved (`CatchUpService`): every pending occurrence due today or earlier, in existing months, dated on its due day instead of now. Just before, the app starts every month missing up to today, one after the other from the latest month (same arithmetic as `Month.dateInterval`), copying its currency, ideal budget and split. The widget doesn't wait for the app: its timeline has one entry per due date and counts due automatic occurrences as if they were recorded (`Month.figures(in:including:)`).
6.  For a **non-recurring transaction**, a `TransactionGroup` and its associated `TransactionEntry` objects are created and saved directly.

Nothing is generated ahead of time, so there is nothing to keep in sync when a rule or a month changes.

## Schema Versioning

All `@Model` classes are nested in `SchemaV1` (see `TrenteSchema.swift`) and exposed through top-level typealiases, so the rest of the app refers to `Month`, `TransactionGroup`, etc. `TrenteMigrationPlan` is passed to every `ModelContainer`.

- **Before the first App Store release:** edit the models in `SchemaV1` directly. No new versions, no migration stages. Breaking the store on test devices is acceptable (reinstall).
- **After release:** never modify a shipped `SchemaVn`. Copy the models into `SchemaVn+1`, apply the change there, point the typealiases at the new version, append it to `TrenteMigrationPlan.schemas` and add a `.lightweight` or `.custom` stage. Test upgrading an on-disk store created by the previous version.
- **iCloud (CloudKit) rules, for every version:** every attribute has a default value or is optional, every relationship is optional, no `@Attribute(.unique)` / `#Unique`, no `.deny` delete rule. To-many relationships are stored as optional arrays (`storedTransactionGroups`, `storedEntries`, `storedTransactions`) and read through non-optional computed properties with the usual names. A group's `month` and an entry's `group` can be `nil` for a moment while a sync is in progress, so code must not force-unwrap them.
- **Once sync has shipped:** CloudKit only accepts new fields. Never rename or remove a stored property; add a new one instead.
- **Duplicates:** each device creates new months and automatic recurring transactions by itself. `SyncDuplicateCleaner` merges months starting the same day and keeps one transaction per recurring rule and day, always keeping the smallest `id` so every device converges on the same records. `CatchUpService` runs it first, before creating missing months, and also when iCloud changes arrive (`NSPersistentStoreRemoteChange`).
- **When freezing a `SchemaVn`:** strip its class bodies down to stored properties and plain inits. Behavior lives in extensions on the typealiases, which follow the current version, so a frozen class must not depend on them.
