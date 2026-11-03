import UIKit
import XCTest

struct Target {
    let frame: CGRect
    let label: String
}

enum CaptureError: Error {
    case missingElement(String)
}

// Lookups go through one snapshot of the accessibility tree and taps go to coordinates:
// element queries are slow while the keyboard is up, and labels change with the language.
@MainActor
final class ShortcutsSetupCaptureTests: XCTestCase {
    private let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
    private var labels: [String: String] = [:]

    private var outputDirectory: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["OUTPUT_DIR"] ?? NSTemporaryDirectory())
    }

    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureWalletAutomation() throws {
        shortcuts.terminate()
        XCUIDevice.shared.system.open(URL(string: "shortcuts://create-shortcut")!)
        dismissWelcomeSheets()

        // Without Apple Intelligence (slim simulators), the editor opens directly and there is no Edit step.
        let screenHeight = shortcuts.frame.height
        let opensInEditor = poll(timeout: 3) { nodes in
            nodes.first { $0.elementType == .searchField && $0.frame.maxY < screenHeight }
        } != nil
        if !opensInEditor {
            let editButton = try find("Edit button") { nodes in
                nodes.filter { $0.elementType == .button && $0.frame.maxY < 130 && $0.frame.width > 0 }
                    .max { $0.frame.minX < $1.frame.minX }
            }
            try capture("Edit", highlighting: [editButton])
            tap(editButton)
        }

        let searchField = try find("search field") { nodes in
            nodes.first { $0.elementType == .searchField }
        }
        let automationChip = try find("Automation chip") { nodes in
            nodes.filter {
                $0.elementType == .button
                    && $0.frame.minY > searchField.frame.maxY
                    && $0.frame.minY < searchField.frame.maxY + 40
                    && $0.frame.height > 30
            }
            .min { $0.frame.minX < $1.frame.minX }
        }
        try capture("Automations", highlighting: [automationChip])
        tap(automationChip)

        let walletCell = shortcuts.cells.containing(.image, identifier: "wallet.fill").firstMatch
        XCTAssert(walletCell.waitForExistence(timeout: 10))
        scrollUntilVisible(walletCell)
        let wallet = Target(frame: walletCell.frame, label: walletCell.label)
        try capture("Wallet", highlighting: [wallet])
        walletCell.tap()

        let actionSearchField = try find("action search field") { nodes in
            nodes.first { $0.elementType == .searchField && $0.frame.minY > 400 }
        }
        try capture("Search", highlighting: [actionSearchField])
        tap(actionSearchField)
        sleep(1)
        shortcuts.typeText("Trente")
        dismissKeyboardTip()

        let actionCell = try find("Trente & Wallet action") { nodes in
            let cells = nodes.filter { $0.elementType == .cell && $0.frame.height > 40 }
                .sorted { $0.frame.minY < $1.frame.minY }
            return cells.count >= 2 ? cells[1] : nil
        }
        try capture("Action", highlighting: [actionCell])
        tap(actionCell)

        let transactionField = try find("Transaction field") { nodes in
            nodes.filter { $0.elementType == .textField }.min { $0.frame.minY < $1.frame.minY }
        }
        tap(transactionField)
        let transactionVariable = try revealWalletVariable()
        try capture("Transaction", highlighting: [transactionField, transactionVariable])
        tap(transactionVariable)

        let amountField = try find("Amount field") { nodes in
            nodes.filter { $0.elementType == .textField }.min { $0.frame.minY < $1.frame.minY }
        }
        tap(amountField)
        let amountVariable = try revealWalletVariable()
        try capture("Amount", highlighting: [amountField, amountVariable])
        tap(amountVariable)

        let amountToken = try textView(at: 1)
        let amountProperty = try walletProperty(at: 3, openingWith: amountToken)
        try capture("Amount Detail", highlighting: [amountProperty])
        tap(amountProperty)

        try closeVariableSheet()
        try capture("Done", around: [try textView(at: 0), try textView(at: 1)], highlighting: [])

        try JSONEncoder().encode(labels).write(to: outputDirectory.appending(path: "labels.json"))
    }

    private func nodes() -> [XCUIElementSnapshot] {
        guard let root = try? shortcuts.snapshot() else { return [] }
        var all: [XCUIElementSnapshot] = []
        var pending = [root]
        while let node = pending.popLast() {
            all.append(node)
            pending.append(contentsOf: node.children)
        }
        return all
    }

    private func find(
        _ description: String,
        timeout: TimeInterval = 10,
        where match: ([XCUIElementSnapshot]) -> XCUIElementSnapshot?
    ) throws -> Target {
        if let target = poll(timeout: timeout, where: match) {
            return target
        }
        try? shortcuts.debugDescription.write(to: outputDirectory.appending(path: "failure.txt"), atomically: true, encoding: .utf8)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: outputDirectory.appending(path: "failure.png"))
        XCTFail("Couldn't find the \(description).")
        throw CaptureError.missingElement(description)
    }

    private func poll(timeout: TimeInterval, where match: ([XCUIElementSnapshot]) -> XCUIElementSnapshot?) -> Target? {
        let deadline = Date.now.addingTimeInterval(timeout)
        repeat {
            if let node = match(nodes()) {
                return Target(frame: node.frame, label: node.label)
            }
            sleep(1)
        } while Date.now < deadline
        return nil
    }

    private func tap(_ target: Target, at relativeX: CGFloat = 0.5) {
        point(x: target.frame.minX + target.frame.width * relativeX, y: target.frame.midY).tap()
    }

    private func point(x: CGFloat, y: CGFloat) -> XCUICoordinate {
        shortcuts.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y))
    }

    private func drag(from start: CGPoint, to end: CGPoint) {
        point(x: start.x, y: start.y).press(forDuration: 0.05, thenDragTo: point(x: end.x, y: end.y))
        sleep(1)
    }

    private func dismissWelcomeSheets() {
        sleep(2)
        dismissContinueButton(timeout: 4)
        XCTAssert(shortcuts.navigationBars.firstMatch.waitForExistence(timeout: 10))
        sleep(2)
    }

    private func dismissKeyboardTip() {
        dismissContinueButton(timeout: 2)
    }

    // The What's New sheet and the keyboard tip each end with one wide Continue button at the bottom.
    private func dismissContinueButton(timeout: TimeInterval) {
        let continueButton = poll(timeout: timeout) { nodes in
            nodes.first { $0.elementType == .button && $0.frame.width > 200 && $0.frame.minY > 700 }
        }
        if let continueButton {
            tap(continueButton)
            sleep(1)
        }
    }

    private func textView(at index: Int) throws -> Target {
        try find("token \(index)") { nodes in
            let views = nodes.filter { $0.elementType == .textView }.sorted { $0.frame.minY < $1.frame.minY }
            return views.count > index ? views[index] : nil
        }
    }

    private func revealWalletVariable() throws -> Target {
        let closeButton = try find("variable bar") { nodes in
            nodes.first { $0.elementType == .button && $0.identifier == "xmark" }
        }
        func lastVariable() throws -> Target {
            try find("Transaction variable") { nodes in
                nodes.filter {
                    $0.elementType == .button
                        && abs($0.frame.midY - closeButton.frame.midY) < 15
                        && $0.identifier != "xmark"
                        && $0.frame.width > 0
                }
                .max { $0.frame.minX < $1.frame.minX }
            }
        }
        var variable = try lastVariable()
        for _ in 0..<8 where variable.frame.maxX > closeButton.frame.minX {
            drag(
                from: CGPoint(x: closeButton.frame.minX - 30, y: closeButton.frame.midY),
                to: CGPoint(x: 20, y: closeButton.frame.midY)
            )
            variable = try lastVariable()
        }
        return variable
    }

    private func sheetGrabber(timeout: TimeInterval) -> Target? {
        poll(timeout: timeout) { nodes in
            nodes.first {
                $0.elementType == .button && abs($0.frame.width - 96) < 3 && abs($0.frame.height - 23) < 3
            }
        }
    }

    private func walletProperty(at index: Int, openingWith token: Target) throws -> Target {
        var grabber: Target?
        for _ in 0..<3 where grabber == nil {
            tap(token, at: 0.7)
            grabber = sheetGrabber(timeout: 4)
        }
        guard let grabber else {
            return try find("variable sheet", timeout: 0) { _ in nil }
        }
        sleep(2)
        return try find("Amount property") { nodes in
            let rows = nodes
                .filter { $0.elementType == .button && $0.frame.minY > grabber.frame.maxY && $0.frame.width > 300 }
                .sorted { $0.frame.minY < $1.frame.minY }
            return rows.count > index ? rows[index] : nil
        }
    }

    private func closeVariableSheet() throws {
        guard let grabber = sheetGrabber(timeout: 4) else { return }
        drag(
            from: CGPoint(x: grabber.frame.midX, y: grabber.frame.midY + 10),
            to: CGPoint(x: grabber.frame.midX, y: shortcuts.frame.maxY - 10)
        )
        sleep(1)
    }

    private func scrollUntilVisible(_ element: XCUIElement) {
        let visibleBottom = shortcuts.frame.maxY - 120
        for _ in 0..<15 where element.frame.maxY > visibleBottom {
            point(x: 201, y: visibleBottom).press(
                forDuration: 0.05,
                thenDragTo: point(x: 201, y: visibleBottom - 200),
                withVelocity: .slow,
                thenHoldForDuration: 0.5
            )
            sleep(1)
        }
        sleep(1)
    }

    private func capture(_ name: String, highlighting targets: [Target]) throws {
        try capture(name, around: targets, highlighting: targets)
    }

    private func capture(_ name: String, around framed: [Target], highlighting highlighted: [Target]) throws {
        sleep(1)
        labels[name] = framed.map(\.label).joined(separator: " | ")
        let screenshot = XCUIScreen.main.screenshot().image
        let image = Self.crop(
            screenshot,
            around: framed.map(\.frame),
            highlighting: highlighted.map(\.frame),
            screenWidth: shortcuts.frame.width
        )
        let data = try XCTUnwrap(image.jpegData(compressionQuality: 0.7))
        try data.write(to: outputDirectory.appending(path: "\(name).jpg"))
        try screenshot.pngData()?.write(to: outputDirectory.appending(path: "\(name) full.png"))
    }

    private static func crop(
        _ screenshot: UIImage,
        around framed: [CGRect],
        highlighting targets: [CGRect],
        screenWidth: CGFloat
    ) -> UIImage {
        let union = framed.dropFirst().reduce(framed[0]) { $0.union($1) }
        let height = max(union.height + 120, 220)
        let minY = min(max(union.midY - height / 2, 0), screenshot.size.height - height)
        let cropRect = CGRect(x: 0, y: minY, width: screenWidth, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: cropRect.size, format: format).image { _ in
            screenshot.draw(at: CGPoint(x: -cropRect.minX, y: -cropRect.minY))
            UIColor.systemOrange.setStroke()
            for target in targets {
                let outline = UIBezierPath(
                    roundedRect: target.offsetBy(dx: -cropRect.minX, dy: -cropRect.minY).insetBy(dx: -5, dy: -5),
                    cornerRadius: min(target.height / 2 + 5, 22)
                )
                outline.lineWidth = 3
                outline.stroke()
            }
        }
    }
}
