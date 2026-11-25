import Foundation
import SwiftUI

struct MenuPrice: View {
    let cents: Int

    var body: some View {
        Text(Decimal(cents) / 100, format: .currency(code: "CNY"))
            .monospacedDigit()
    }
}

@MainActor
struct DemoMenuView: View {
    let cart: CartModel
    @State private var search = ""

    private var keyword: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var categories: [MenuCategory] {
        guard !keyword.isEmpty else { return MenuCategory.demo }
        return MenuCategory.demo.compactMap { category in
            let matching = category.dishes.filter {
                $0.name.localizedStandardContains(keyword) || category.name.localizedStandardContains(keyword)
            }
            guard !matching.isEmpty else { return nil }
            return MenuCategory(id: category.id, name: category.name, dishes: matching)
        }
    }

    var body: some View {
        let categories = categories
        List {
            Section {
                Text("示例菜品和价格仅用于体验选菜。")
                    .foregroundStyle(.secondary)
            }
            ForEach(categories) { category in
                Section(category.name) {
                    ForEach(category.dishes) { dish in
                        NavigationLink {
                            DishDetailView(dish: dish, cart: cart)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(dish.name).font(.headline)
                                Text(dish.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if dish.available {
                                    MenuPrice(cents: dish.price)
                                        .font(.subheadline.weight(.semibold))
                                } else {
                                    Text("已售罄")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            if categories.isEmpty {
                ContentUnavailableView.search(text: keyword)
            }
        }
        .navigationTitle("演示菜单")
        .searchable(text: $search, prompt: "搜索菜品或分类")
    }
}

@MainActor
private struct DishDetailView: View {
    let dish: Dish
    let cart: CartModel
    @State private var selection: [String]
    @State private var quantity = 1
    @State private var feedback: String?
    @State private var addCount = 0

    init(dish: Dish, cart: CartModel) {
        self.dish = dish
        self.cart = cart
        _selection = State(initialValue: dish.defaultSelection)
    }

    private var unitPrice: Int {
        dish.price + (dish.options(for: selection) ?? []).reduce(0) { $0 + $1.supplement }
    }

    var body: some View {
        Form {
            Section {
                Text(dish.description)
                LabeledContent("示例单价") { MenuPrice(cents: unitPrice) }
            }
            if dish.available {
                Section("选规格") {
                    ForEach(dish.groups.indices, id: \.self) { index in
                        let group = dish.groups[index]
                        Picker(group.name, selection: $selection[index]) {
                            ForEach(group.options) { option in
                                if option.supplement > 0 {
                                    let amount = (Decimal(option.supplement) / 100).formatted(.currency(code: "CNY"))
                                    Text("\(option.name) +\(amount)")
                                        .tag(option.id)
                                } else {
                                    Text(option.name).tag(option.id)
                                }
                            }
                        }
                    }
                    Stepper("数量 \(quantity)", value: $quantity, in: 1...CartModel.quantityLimit)
                }
                Section {
                    LabeledContent("菜品小计") { MenuPrice(cents: unitPrice * quantity) }
                    Button {
                        if cart.add(dish, selection: selection, quantity: quantity) {
                            feedback = "已加入演示购物车"
                            addCount += 1
                        } else {
                            feedback = "此规格最多添加 \(CartModel.quantityLimit) 份，请调整数量。"
                        }
                    } label: {
                        Label("加入购物车", systemImage: "cart.badge.plus")
                            .frame(minHeight: 44)
                    }
                    if let feedback {
                        Text(feedback)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
            } else {
                Section { Label("已售罄", systemImage: "info.circle") }
            }
        }
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: addCount)
        .onChange(of: selection) { _, _ in feedback = nil }
        .onChange(of: quantity) { _, _ in feedback = nil }
    }
}

@MainActor
struct CartView: View {
    let cart: CartModel
    @State private var confirmingClear = false

    var body: some View {
        List {
            if cart.lines.isEmpty {
                ContentUnavailableView {
                    Label("购物车是空的", systemImage: "cart")
                } description: {
                    Text("从演示菜单选菜，购物车会保存在本机。")
                } actions: {
                    NavigationLink("打开演示菜单") { DemoMenuView(cart: cart) }
                        .buttonStyle(.bordered)
                }
                .listRowSeparator(.hidden)
            } else {
                Section("演示菜品") {
                    ForEach(cart.lines) { line in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(line.name).font(.headline)
                            if !line.optionNames.isEmpty {
                                Text(line.optionNames.joined(separator: " · "))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            LabeledContent("小计") { MenuPrice(cents: line.subtotal) }
                            Stepper(value: Binding(
                                get: { cart.lines.first { $0.id == line.id }?.quantity ?? line.quantity },
                                set: { cart.setQuantity($0, for: line.id) }
                            ), in: 1...CartModel.quantityLimit) {
                                Text("数量 \(line.quantity)")
                                    .accessibilityLabel("\(line.name) 数量 \(line.quantity)")
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) { cart.remove(line.id) } label: { Label("移除", systemImage: "trash") }
                        }
                    }
                }
                Section {
                    LabeledContent("共 \(cart.itemCount) 份") {
                        MenuPrice(cents: cart.subtotal).fontWeight(.semibold)
                    }
                    NavigationLink("继续选菜") { DemoMenuView(cart: cart) }
                    Button("清空购物车", role: .destructive) { confirmingClear = true }
                } footer: {
                    Text("金额为示例菜品的本机小计，未包含配送、包装或优惠。")
                }
            }
        }
        .navigationTitle("购物车")
        .confirmationDialog("清空购物车？", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("清空购物车", role: .destructive) { cart.clear() }
        }
    }
}
