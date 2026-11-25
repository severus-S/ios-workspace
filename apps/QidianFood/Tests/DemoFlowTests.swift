import Foundation
import XCTest
@testable import QidianCatalog

final class DemoFlowTests: XCTestCase {
    private func isolatedDefaults() throws -> (String, UserDefaults) {
        let suite = "QidianDemoTests.\(UUID())"
        return (suite, try XCTUnwrap(UserDefaults(suiteName: suite)))
    }

    @MainActor
    func testCartSeparatesVariantsAndRestoresQuantities() async throws {
        let (suite, defaults) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let dish = try XCTUnwrap(MenuCategory.demo.first?.dishes.first)
        let cart = CartModel(defaults: defaults)
        XCTAssertTrue(cart.add(dish, selection: dish.defaultSelection, quantity: 2))
        XCTAssertTrue(cart.add(dish, selection: ["large", "regular"], quantity: 1))
        XCTAssertTrue(cart.add(dish, selection: dish.defaultSelection, quantity: 1))

        let restored = CartModel(defaults: defaults)
        XCTAssertEqual(restored.lines.map(\.quantity), [3, 1])
        XCTAssertEqual(restored.lines.map(\.unitPrice), [1680, 1980])
        XCTAssertEqual(restored.subtotal, 7020)
        restored.setQuantity(2, for: restored.lines[0].id)
        restored.remove(restored.lines[1].id)
        XCTAssertEqual(CartModel(defaults: defaults).subtotal, 3360)
        restored.clear()
        XCTAssertTrue(CartModel(defaults: defaults).lines.isEmpty)
    }

    @MainActor
    func testCartRejectsInvalidVariantsAndUnavailableDishes() async throws {
        let (suite, defaults) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let dish = try XCTUnwrap(MenuCategory.demo.first?.dishes.first)
        let soldOut = try XCTUnwrap(MenuCategory.demo.flatMap(\.dishes).first(where: { !$0.available }))
        let cart = CartModel(defaults: defaults)
        XCTAssertFalse(cart.add(dish, selection: ["large"], quantity: 1))
        XCTAssertFalse(cart.add(soldOut, selection: soldOut.defaultSelection, quantity: 1))
        XCTAssertFalse(cart.add(dish, selection: dish.defaultSelection, quantity: 0))
        XCTAssertTrue(cart.add(dish, selection: dish.defaultSelection, quantity: CartModel.quantityLimit))
        XCTAssertFalse(cart.add(dish, selection: dish.defaultSelection, quantity: 1))
        XCTAssertEqual(cart.itemCount, CartModel.quantityLimit)
    }

    @MainActor
    func testDemoCodeExpiresAndSignOutClearsPersistedState() async throws {
        let (suite, defaults) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let account = DemoAccount(defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(account.verify("000000", now: start), .missing)
        account.generateCode(now: start)
        let firstCode = try XCTUnwrap(account.code)
        XCTAssertEqual(account.verify("000000", now: start), .mismatch)
        XCTAssertEqual(account.verify(firstCode, now: start.addingTimeInterval(120)), .expired)
        account.generateCode(now: start)
        let secondCode = try XCTUnwrap(account.code)
        XCTAssertEqual(account.verify(secondCode, now: start), .accepted)
        XCTAssertNil(account.code)
        let restored = DemoAccount(defaults: defaults)
        XCTAssertTrue(restored.isSignedIn)
        restored.signOut()
        XCTAssertFalse(DemoAccount(defaults: defaults).isSignedIn)
    }

    func testLocalAddressNormalizesOptionalPhoneAndPreservesIdentity() throws {
        let raw = DeliveryAddress(recipient: " 测试 ", phone: "139 0000 0000", detail: "  示例楼栋  ")
        let cleaned = try XCTUnwrap(raw.cleaned)
        XCTAssertEqual(cleaned.id, raw.id)
        XCTAssertEqual(cleaned.recipient, "测试")
        XCTAssertEqual(cleaned.phone, "13900000000")
        XCTAssertEqual(cleaned.detail, "示例楼栋")
        XCTAssertNotNil(DeliveryAddress(recipient: "测试", detail: "示例楼栋").cleaned)
        XCTAssertNil(DeliveryAddress(recipient: "测试", phone: "12", detail: "示例楼栋").cleaned)
        XCTAssertNil(DeliveryAddress(recipient: "", detail: "示例楼栋").cleaned)
    }
}
