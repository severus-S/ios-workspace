import Foundation
import Observation

@MainActor
@Observable
final class DemoAccount {
    enum Verification: Equatable {
        case accepted, missing, expired, mismatch
    }

    static let phone = "139 •••• 0000"
    static let name = "蒲河体验账号"
    private static let storageKey = "qidianfood.demoSession.v1"

    private let defaults: UserDefaults
    private(set) var isSignedIn: Bool
    private(set) var code: String?
    private var expiration: Date?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSignedIn = defaults.bool(forKey: Self.storageKey)
    }

    func generateCode(now: Date = .now) {
        code = String(Int.random(in: 100_000...999_999))
        expiration = now.addingTimeInterval(120)
    }

    func verify(_ input: String, now: Date = .now) -> Verification {
        guard let code, let expiration else { return .missing }
        guard now < expiration else {
            clearChallenge()
            return .expired
        }
        guard input == code else { return .mismatch }
        clearChallenge()
        isSignedIn = true
        defaults.set(true, forKey: Self.storageKey)
        return .accepted
    }

    func clearChallenge() {
        code = nil
        expiration = nil
    }

    func signOut() {
        clearChallenge()
        defaults.removeObject(forKey: Self.storageKey)
        isSignedIn = false
    }
}

struct DeliveryAddress: Codable, Equatable, Identifiable {
    let id: UUID
    var recipient: String
    var phone: String
    var detail: String

    init(id: UUID = UUID(), recipient: String = "", phone: String = "", detail: String = "") {
        self.id = id
        self.recipient = recipient
        self.phone = phone
        self.detail = detail
    }

    var cleaned: Self? {
        let recipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phone.filter { !$0.isWhitespace }
        let detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...30).contains(recipient.count), (1...120).contains(detail.count),
              phone.isEmpty || (phone.count == 11 && phone.first == "1" && phone.utf8.allSatisfy { (48...57).contains($0) })
        else { return nil }
        return .init(id: id, recipient: recipient, phone: phone, detail: detail)
    }
}

struct DemoOrder: Identifiable, Sendable {
    struct Item: Identifiable, Sendable {
        let id: String
        let name: String
        let specification: String
        let quantity: Int
        let price: Int
    }

    let id: String
    let shop: String
    let date: Date
    let state: String
    let items: [Item]

    var total: Int { items.reduce(0) { $0 + $1.price * $1.quantity } }

    static let history: [Self] = [
        .init(id: "DEMO-002", shop: "午间食堂", date: Date(timeIntervalSince1970: 1_763_956_800), state: "已完成",
              items: [
                .init(id: "rice", name: "照烧鸡腿饭", specification: "标准份 · 原味照烧", quantity: 1, price: 1680),
                .init(id: "tea", name: "柠檬红茶", specification: "少冰", quantity: 1, price: 750)
              ]),
        .init(id: "DEMO-001", shop: "午间食堂", date: Date(timeIntervalSince1970: 1_763_784_000), state: "已取消",
              items: [.init(id: "pumpkin", name: "盐烤南瓜", specification: "", quantity: 2, price: 600)])
    ]
}
