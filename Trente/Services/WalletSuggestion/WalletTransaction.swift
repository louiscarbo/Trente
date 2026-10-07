import Foundation

struct WalletTransaction: Hashable, Sendable {
    var merchant: String
    var name: String
    var amount: String
    var card: String
}
