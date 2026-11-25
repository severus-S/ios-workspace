import Foundation
import Security
import SwiftUI

private enum AddressBookStorage {
    private static let key: [String: String] = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.sjx13.ios.qidianfood.local-addresses",
        kSecAttrAccount as String: "v1"
    ]

    static func load() throws -> [DeliveryAddress] {
        var query: [String: Any] = key
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let data = result as? Data else { throw StorageError.unavailable }
        return try JSONDecoder().decode([DeliveryAddress].self, from: data)
    }

    static func save(_ addresses: [DeliveryAddress]) throws {
        if addresses.isEmpty {
            let status = SecItemDelete(key as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw StorageError.unavailable }
            return
        }
        let data = try JSONEncoder().encode(addresses)
        let changes = [kSecValueData as String: data] as CFDictionary
        let status = SecItemUpdate(key as CFDictionary, changes)
        if status == errSecItemNotFound {
            var attributes: [String: Any] = key
            attributes[kSecValueData as String] = data
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else { throw StorageError.unavailable }
        } else if status != errSecSuccess {
            throw StorageError.unavailable
        }
    }

    private enum StorageError: Error { case unavailable }
}

@MainActor
struct AddressBookView: View {
    @State private var addresses: [DeliveryAddress] = []
    @State private var editing: DeliveryAddress?
    @State private var removal: DeliveryAddress?
    @State private var hasLoaded = false
    @State private var error: String?

    var body: some View {
        List {
            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                    if !hasLoaded {
                        Button("重试") { load() }
                    }
                }
            }
            if hasLoaded && addresses.isEmpty {
                ContentUnavailableView("还没有地址", systemImage: "location",
                                       description: Text("点右上角加号，添加一个本机地址。"))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(addresses) { address in
                    Button {
                        editing = address
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(address.recipient).font(.headline).foregroundStyle(.primary)
                            Text(address.detail).foregroundStyle(.primary)
                            if !address.phone.isEmpty {
                                Text(address.phone).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            removal = address
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("收货地址")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = DeliveryAddress() } label: {
                    Label("添加地址", systemImage: "plus")
                }
                .disabled(!hasLoaded)
            }
        }
        .task { if !hasLoaded { load() } }
        .sheet(item: $editing) { address in
            AddressEditor(address: address, isNew: !addresses.contains { $0.id == address.id }) { address in
                var updated = addresses
                if let index = updated.firstIndex(where: { $0.id == address.id }) {
                    updated[index] = address
                } else {
                    updated.append(address)
                }
                try AddressBookStorage.save(updated)
                addresses = updated
                error = nil
            }
        }
        .confirmationDialog("删除该地址？", isPresented: Binding(
            get: { removal != nil },
            set: { if !$0 { removal = nil } }
        ), titleVisibility: .visible, presenting: removal) { address in
            Button("删除地址", role: .destructive) {
                do {
                    let updated = addresses.filter { $0.id != address.id }
                    try AddressBookStorage.save(updated)
                    addresses = updated
                    error = nil
                } catch {
                    self.error = "地址删除失败。请在设备解锁时重试。"
                }
            }
        }
    }

    private func load() {
        do {
            addresses = try AddressBookStorage.load()
            hasLoaded = true
            error = nil
        } catch {
            self.error = "暂时无法读取本机地址。请在设备解锁时重试。"
        }
    }
}

@MainActor
private struct AddressEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address: DeliveryAddress
    let isNew: Bool
    let onSave: (DeliveryAddress) throws -> Void
    @State private var error: String?

    init(address: DeliveryAddress, isNew: Bool, onSave: @escaping (DeliveryAddress) throws -> Void) {
        _address = State(initialValue: address)
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("收货人", text: $address.recipient)
                    TextField("手机号（选填）", text: $address.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("楼栋、门牌或取餐点", text: $address.detail, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("地址仅保存在此设备。手机号选填，填写时使用 11 位手机号。")
                }
                if let error {
                    Text(error).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isNew ? "添加地址" : "编辑地址")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
        }
    }

    private func save() {
        guard let address = address.cleaned else {
            error = "请填写 1–30 字的收货人及 1–120 字的地址，并检查选填的手机号。"
            return
        }
        do {
            try onSave(address)
            dismiss()
        } catch {
            self.error = "地址保存失败。请在设备解锁时重试。"
        }
    }
}
