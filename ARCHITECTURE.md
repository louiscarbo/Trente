# Architecture

How Trente's code is organised and the rules it follows. This file holds only settled decisions. Open questions live on the Roadmap card "Stricter, well-defined architecture rules and enforcement" and its page "Architecture audit: your calls", along with the places where the code doesn't follow this file yet. When a decision changes, update this file in the same change.

The transaction domain model is explained in [`Trente/Model/README.md`](Trente/Model/README.md).

## Layers

Each layer may use the layers below it, never the ones above.

1. **App shell**: `TrenteApp`, the widget, App Intents, `NotificationDelegate`, UIKit and AppKit glue. It may use every layer, and no layer uses it.
2. **Screens** (`Views/Screens`): root views, view models, and each screen's own leaf views.
3. **Design System** (`Views/Design System`): leaf views used by more than one screen, and styles. It never sees screens, services or an `@Model` type: once modules exist, it imports `TrenteValues`, never `TrenteModel`.
4. **Services** (`Services/`): the app's operations: fetching and saving, notifications, iCloud sync, Trente+, export and import. No domain rules, no screens and no SwiftUI; UIKit and AppKit are fine for system wrappers such as `Device`, `Pasteboard` and `AppIconSwitcher`. A service never returns a UI type.
5. **Model** (`Model/`): SwiftData models, value types such as `BudgetCategory` and `Currency`, drafts, and the domain rules. It depends on nothing of ours. Once modules exist it is two packages: `TrenteValues` holds the value types the models store and the rules on them, and never imports SwiftData; `TrenteModel` holds the SwiftData models, the drafts and the rules that need a model, and imports `TrenteValues`.

## Views

- A **leaf view** takes plain values only: strings, numbers, dates, value enums, bindings and action closures. Never an `@Model` object, so its preview needs nothing else.
- A **root view** orchestrates one screen, or one row that maps a model and owns its actions. It owns the models, `modelContext`, `@Query` and fetching, maps models to leaf inputs, owns navigation and presentation, and turns user actions into calls to Services.
- A leaf may present plain content itself: a confirmation dialog, a picker, its own sheet of plain values. Presenting or pushing a view that needs models or services is root work.
- A leaf in Screens may take a plain value type declared in Services, such as `CloudSyncStatus`. A Design System component never does.
- A view nested in its screen (`Screen+Piece.swift`) is always a leaf. A top-level view (a screen, a step, a row) may be a root.
- A root only composes views and attaches navigation, presentation and data modifiers. Styled layout goes in a leaf.
- A leaf never names a Services type: its root passes in what it needs, text included.
- A screen's own leaf views stay with that screen, nested as `Screen+Piece.swift` containing `extension Screen { struct Piece: View }`.
- Leaf views take flat parameters. No `Item` or `Summary` struct whose only job is to bundle them, and no `init(model:)` mapping in a leaf's file.
- The Design System holds no domain logic and no model mapping, not even in a companion file in the same folder.
- The Design System reads app state only through environment values it declares itself, such as whether Trente+ is active and the action that shows the paywall. `TrenteApp` provides them.
- Content a screen shows, such as the FAQ, the credits or the Trente+ benefits, is a UI model: it lives in Screens, next to the screen that shows it, never in Model.
- Custom styles (button, toggle, label and gauge styles) live in the Design System even when one screen uses them, so they are easy to find and reuse.
- Before adding a component, look in `Views/Design System/Components`: new designs evolve the components we have. Sheets close with `CloseToolbarItem` and step through flows with `StepNavigationBar`.

## View models

A screen gets a view model only when it has real logic of its own, like the steps and image loading in `NewTransactionViewModel`. A view model lives with its screen. Lots of screens don't need one.

## Drafts

A draft is an editable copy of one model: `init(from:)`, `validate()`, `apply(to:)`. Drafts are data models, so they belong in Model. `TransactionCreationRequest` is the draft for a new transaction.

## Domain rules

Model says what's true and what's allowed. Services make it happen.

- A domain rule is written once, in Model, as an extension on the model's typealias, next to `Month.spentAmount(for:)`. Examples: how a transaction splits into entries, what confirming or skipping a recurring occurrence does, how a new month starts from the previous one.
- A rule lives with the types it acts on: a rule on plain values (splits, cents, schedules) in `TrenteValues`, a rule that needs a model in `TrenteModel`.
- Validation lives in Model and returns problems as values, one validation per kind of record for every path that writes it. The screens turn problems into text.
- Amounts are hundredths of the main unit for every currency, even yen. Convert only through the pair of functions in `TrenteValues`, never with `* 100` or `/ 100`.
- The service around a rule fetches what it needs, calls the rule, saves, and handles side effects such as notifications and Trente+ checks.
- Once Model is a package, the stored properties a rule guards are `public internal(set)`: other modules can read them, and only Model changes them.

## Services

- A service with no stored state is an enum with static functions, never a singleton.

## State

There is no app-wide state object. SwiftData is the app's state and storage: root views read with `@Query` and write through `ModelContext` and Services.

An object that holds state lives in the environment when views read it (`CloudSyncMonitor`, the routers), is owned by `TrenteApp` when only the app uses it (`NotificationScheduler`, `WidgetRefresher`), and is `.shared` only when exactly one must exist for the system or for several layers (`TrentePlusStatus`, `CatchUpService`, `NotificationDelegate`, `TrenteContainer`). Navigation state, such as the routers, lives in Screens.

## Files

- One primary type per file. Small companions that only serve it, such as an error or option enum, may share its file.
- A destination screen, or a type used by several screens, gets its own top-level file.
- Folders are synchronized with the file system: a new file joins the app target with no project edit.
- The widget compiles a hand-picked list of app files (`membershipExceptions` in the project file). Don't move those files or reference app-only types from them, and build the `Trente` scheme after touching them, since `Trente Dev` doesn't build the widget. This goes away once the widget imports the four packages.

## Modules

Planned. Each layer becomes a local Swift package, so the compiler enforces the direction: a file has to `import` a layer to use it, and a package can't import one above it.

- Four packages: `TrenteValues` and `TrenteModel` first, then `TrenteDesignSystem`, which imports `TrenteValues` only, then `TrenteServices`. The widget is an app target like the app, so it may import all four.
- Everything that crosses a package boundary is `public`, member by member, not only the type.
- Each package has its own String Catalog. Code inside a package must name the package's bundle (`bundle: .module`), or it looks up the app's catalog and silently shows English. Display names stay with their types, such as `BudgetCategory.name` in `TrenteValues`. Keep strings out of packages where possible: Design System components take their text from the caller. The `xcstrings` merge driver applies to every catalog, and each translation pass covers every catalog, fr-CA included.

## Enforcement

- SwiftLint runs on every build through the SwiftLintPlugins build plugin, pinned to one version, and as a gate in Xcode Cloud's `ci_post_clone.sh`. The architecture rules are custom rules with `severity: error`.
- An architecture test package reads the sources and checks what lint can't, such as layer direction and fr-CA in every String Catalog. It runs in CI.
- Each package turns on `MemberImportVisibility`, `InternalImportsByDefault` and the explicit target dependency check.

## Persistence

- Models are nested in versioned schemas (`SchemaV1` in `TrenteSchema.swift`) and used through top-level typealiases. Behavior lives in extensions on the typealiases. The migration workflow is in [`Trente/Model/README.md`](Trente/Model/README.md).
- Every new schema version ships with upgrade tests in `TrenteTests`.

## Navigation

Root views own navigation and presentation. A design for navigation across the whole app is planned on its own Roadmap card.
