import Foundation
import Observation

struct Dish: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let groups: [Group]
    var available = true

    struct Group: Identifiable, Sendable {
        let id: String
        let name: String
        let options: [Option]
    }

    struct Option: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        var supplement = 0
    }

    var defaultSelection: [String] {
        groups.compactMap { $0.options.first?.id }
    }

    func options(for selection: [String]) -> [Option]? {
        guard selection.count == groups.count else { return nil }
        let options = zip(groups, selection).compactMap { group, id in
            group.options.first { $0.id == id }
        }
        return options.count == groups.count ? options : nil
    }
}

struct MenuCategory: Identifiable, Sendable {
    let id: String
    let name: String
    let dishes: [Dish]

    static let demo: [Self] = [
        .init(id: "rice", name: "饭食", dishes: [
            .init(id: "chicken-rice", name: "照烧鸡腿饭",
                  description: "照烧鸡腿配米饭、西兰花和胡萝卜。",
                  price: 1680, groups: [
                    .init(id: "size", name: "份量", options: [
                        .init(id: "regular", name: "标准份"),
                        .init(id: "large", name: "加大份", supplement: 300)
                    ]),
                    .init(id: "sauce", name: "酱汁", options: [
                        .init(id: "regular", name: "原味照烧"),
                        .init(id: "spicy", name: "微辣照烧")
                    ])
                  ]),
            .init(id: "mushroom-rice", name: "香菇滑鸡饭",
                  description: "香菇鸡肉、蒸米饭和当季青菜。", price: 1580, groups: [])
        ]),
        .init(id: "sides", name: "小食", dishes: [
            .init(id: "pumpkin", name: "盐烤南瓜",
                  description: "南瓜厚切烤制，撒少许海盐。", price: 600, groups: []),
            .init(id: "egg", name: "卤蛋",
                  description: "一份一颗。", price: 200, groups: [], available: false)
        ]),
        .init(id: "drinks", name: "饮品", dishes: [
            .init(id: "tea", name: "柠檬红茶",
                  description: "红茶搭配鲜柠檬，500 毫升。",
                  price: 750, groups: [
                    .init(id: "temperature", name: "温度", options: [
                        .init(id: "cold", name: "少冰"),
                        .init(id: "room", name: "常温")
                    ])
                  ])
        ])
    ]
}

struct CartLine: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let dishID: String
    let name: String
    let optionIDs: [String]
    let optionNames: [String]
    let unitPrice: Int
    var quantity: Int

    var subtotal: Int { unitPrice * quantity }
}

@MainActor
@Observable
final class CartModel {
    static let quantityLimit = 99
    private static let storageKey = "qidianfood.demoCart.v1"
    private let defaults: UserDefaults
    private(set) var lines: [CartLine]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([CartLine].self, from: data) {
            lines = saved.filter { (1...Self.quantityLimit).contains($0.quantity) && (0...1_000_000).contains($0.unitPrice) }
        } else {
            lines = []
        }
    }

    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var subtotal: Int { lines.reduce(0) { $0 + $1.subtotal } }

    @discardableResult
    func add(_ dish: Dish, selection: [String], quantity: Int) -> Bool {
        guard dish.available, (1...Self.quantityLimit).contains(quantity),
              let options = dish.options(for: selection) else { return false }
        if let index = lines.firstIndex(where: { $0.dishID == dish.id && $0.optionIDs == selection }) {
            let newQuantity = lines[index].quantity + quantity
            guard newQuantity <= Self.quantityLimit else { return false }
            lines[index].quantity = newQuantity
        } else {
            lines.append(.init(id: UUID(), dishID: dish.id, name: dish.name,
                               optionIDs: selection, optionNames: options.map(\.name),
                               unitPrice: dish.price + options.reduce(0) { $0 + $1.supplement },
                               quantity: quantity))
        }
        save()
        return true
    }

    func setQuantity(_ quantity: Int, for id: CartLine.ID) {
        guard (1...Self.quantityLimit).contains(quantity),
              let index = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[index].quantity = quantity
        save()
    }

    func remove(_ id: CartLine.ID) {
        lines.removeAll { $0.id == id }
        save()
    }

    func clear() {
        lines = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(lines) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
