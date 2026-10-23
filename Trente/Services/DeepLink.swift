//
//  DeepLink.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum DeepLink: Hashable {
    case month(id: UUID)
    case newTransaction(monthID: UUID)

    static let scheme = "trente"

    private enum Host {
        static let month = "month"
        static let newTransaction = "newtransaction"
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              let host = url.host(percentEncoded: false)?.lowercased()
        else { return nil }
        let pathItems = url.pathComponents.filter { $0 != "/" }
        guard pathItems.count == 1, let id = UUID(uuidString: pathItems[0]) else { return nil }
        switch host {
        case Host.month:
            self = .month(id: id)
        case Host.newTransaction:
            self = .newTransaction(monthID: id)
        default:
            return nil
        }
    }

    var url: URL {
        switch self {
        case .month(let id):
            Self.url(host: Host.month, id: id)
        case .newTransaction(let monthID):
            Self.url(host: Host.newTransaction, id: monthID)
        }
    }

    var monthID: UUID {
        switch self {
        case .month(let id), .newTransaction(let id):
            id
        }
    }

    private var opensNewTransaction: Bool {
        if case .newTransaction = self { true } else { false }
    }

    func destination(in months: [Month]) -> DeepLinkDestination? {
        if let month = months.first(where: { $0.id == monthID }) {
            return DeepLinkDestination(month: month, opensNewTransaction: opensNewTransaction)
        }
        return months.first.map { DeepLinkDestination(month: $0, opensNewTransaction: false) }
    }

    private static func url(host: String, id: UUID) -> URL {
        URL(string: "\(scheme)://\(host)/\(id.uuidString)")!
    }
}

struct DeepLinkDestination {
    let month: Month
    let opensNewTransaction: Bool
}
