# Trente Project

## WHY (Purpose)
Trente is an iOS and macOS budgeting application. It is designed to track user finances on a monthly basis, handling one-time expenses, categorized income distributions, and complex recurring transactions.

## WHAT (Tech Stack & Structure)
- **Core Stack:** Swift, SwiftUI, SwiftData.
- **Project Structure:**
  - `Trente/Model/`: Core data models (using SwiftData). See `Trente/Model/README.md` for an in-depth explanation of the transaction domain model.
  - `Trente/Services/`: Business logic and data manipulation interfaces (e.g., `MonthService`, `TransactionService`).
  - `Trente/Views/`: UI components organized into `Screens`, `Design System`, and `Utils`.
  - `TrenteTests/`: XCTest unit tests.
  - `TrenteWidget/`: Widget extension target.

## HOW (Working on the Project)
- **Code Style:** We use SwiftLint. A `.swiftlint.yml` configuration is at the root. Follow the existing codebase conventions and let the linter guide formatting.
- **Testing:** Add tests for new business logic in `TrenteTests/`. Run tests via Xcode (`Cmd+U`) or via `xcodebuild`.
- **Building:** The project provides `Trente` and `Trente Dev` schemes.
- **Data Architecture:** Before modifying the transaction data logic, read the `Trente/Model/README.md` file carefully.
