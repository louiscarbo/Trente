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
- **Simulators:** Use `Slim 1` to `Slim 4` (iPhone 17, iOS 27.0, slimmed with `simslim`), headless, up to four alongside one build. The test suite runs on them. Shut them down when done and keep them, because the first boot is the heaviest part. If one is missing, create it with `xcrun simctl create` and `simslim on <udid> --preserve-boot-state`.
- **Stock simulators:** Use one, alone, only for what a slim simulator can't show: widgets, Live Activities, iCloud sync, StoreKit purchases, Shortcuts and App Intents, the document picker, store captures.
- **Architecture:** Before adding a file or moving code between layers, read `ARCHITECTURE.md`. Update it in the same change when an architecture decision changes.
- **Data Architecture:** Before modifying the transaction data logic, read the `Trente/Model/README.md` file carefully.
