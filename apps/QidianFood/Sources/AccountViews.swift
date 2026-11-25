import Foundation
import SwiftUI

@MainActor
struct AccountView: View {
    let account: DemoAccount

    var body: some View {
        List {
            Section {
                if account.isSignedIn {
                    NavigationLink { DemoProfileView() } label: {
                        Label("本人资料", systemImage: "person.text.rectangle")
                    }
                    NavigationLink { AddressBookView() } label: {
                        Label("收货地址", systemImage: "location")
                    }
                    NavigationLink { DemoOrdersView() } label: {
                        Label("历史订单", systemImage: "list.bullet.rectangle")
                    }
                } else {
                    NavigationLink { DemoLoginView(account: account) } label: {
                        Label("体验短信登录", systemImage: "message")
                    }
                }
            } header: {
                Text("演示账号")
            } footer: {
                Text("演示使用本机验证码和示例订单。手动添加的地址只保存在此设备。")
            }
            if account.isSignedIn {
                Section {
                    Button("退出演示账号", role: .destructive) { account.signOut() }
                }
            }
        }
        .navigationTitle("我的")
    }
}

@MainActor
private struct DemoLoginView: View {
    let account: DemoAccount
    @Environment(\.dismiss) private var dismiss
    @FocusState private var enteringCode: Bool
    @State private var input = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("示例手机号", value: DemoAccount.phone)
                Button(account.code == nil ? "生成演示验证码" : "重新生成") {
                    input = ""
                    error = nil
                    account.generateCode()
                    enteringCode = true
                }
                .frame(minHeight: 44, alignment: .leading)
                if let code = account.code {
                    LabeledContent("演示验证码", value: code)
                        .monospacedDigit()
                    TextField("输入 6 位验证码", text: $input)
                        .keyboardType(.numberPad)
                        .focused($enteringCode)
                        .accessibilityLabel("输入 6 位演示验证码")
                        .onChange(of: input) { _, value in
                            let digits = value.filter { $0.isASCII && $0.isNumber }
                            let cleaned = String(digits.prefix(6))
                            if input != cleaned { input = cleaned }
                            error = nil
                        }
                }
            } footer: {
                Text("验证码在本机生成，2 分钟内有效。演示不会发送短信。")
            }
            Section {
                Button("登录演示账号") {
                    switch account.verify(input) {
                    case .accepted: dismiss()
                    case .missing: error = "请先生成验证码。"
                    case .expired: error = "验证码已过期，请重新生成。"
                    case .mismatch: error = "验证码不匹配，请核对上方数字。"
                    }
                }
                .frame(minHeight: 44, alignment: .leading)
                .disabled(input.count != 6 || account.code == nil)
                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
        .navigationTitle("短信登录演示")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { account.clearChallenge() }
    }
}

@MainActor
private struct DemoProfileView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("昵称", value: DemoAccount.name)
                LabeledContent("手机号", value: DemoAccount.phone)
                LabeledContent("校区", value: CatalogAPI.campusName)
            } header: {
                Text("示例资料")
            }
        }
        .navigationTitle("本人资料")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DemoOrdersView: View {
    var body: some View {
        List {
            Section("示例订单") {
                ForEach(DemoOrder.history) { order in
                    NavigationLink {
                        DemoOrderDetailView(order: order)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(order.shop).font(.headline)
                            Text(order.date, format: .dateTime.year().month().day())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            LabeledContent(order.state) { MenuPrice(cents: order.total) }
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("历史订单")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DemoOrderDetailView: View {
    let order: DemoOrder

    var body: some View {
        List {
            Section("示例订单") {
                LabeledContent("商家", value: order.shop)
                LabeledContent("状态", value: order.state)
                LabeledContent("编号", value: order.id)
            }
            Section("菜品") {
                ForEach(order.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        LabeledContent("\(item.name) × \(item.quantity)") {
                            MenuPrice(cents: item.price * item.quantity)
                        }
                        if !item.specification.isEmpty {
                            Text(item.specification)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                LabeledContent("示例合计") { MenuPrice(cents: order.total).fontWeight(.semibold) }
            }
        }
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}
