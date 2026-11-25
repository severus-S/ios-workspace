import Foundation
import XCTest
@testable import QidianCatalog

final class CatalogTests: XCTestCase {
    func testRequestPreservesCampusIdentifierAndSearchParameters() throws {
        let request = try CatalogAPI.request(page: 2, keyword: "示例店")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(json["campusId"] as? String, "1369455724900470786")
        XCTAssertEqual(json["current"] as? Int, 2)
        XCTAssertEqual(json["keywords"] as? String, "示例店")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNil(request.value(forHTTPHeaderField: "Cookie"))
    }

    func testResponseDecodesPublicFieldsAndRejectsUntrustedImageHosts() throws {
        let response = """
        {"code":"10000","data":{"records":[
          {"id":"9007199254740993","storeName":"示例店","minimumAmount":4.25,
           "storeImagePath":"https://oss.hebooming.com/example.jpg","extra":true},
          {"id":"2","storeName":"第二家","storeImagePath":"https://noncatalog.example/photo.jpg"}
        ]}}
        """
        let shops = try CatalogAPI.decodePage(Data(response.utf8), status: 200)
        XCTAssertEqual(shops.map(\.id), ["9007199254740993", "2"])
        XCTAssertEqual(shops[0].positiveMinimum, Decimal(string: "4.25"))
        XCTAssertEqual(shops[0].imageURL?.host, "oss.hebooming.com")
        XCTAssertNil(shops[1].imageURL)
    }

    func testAuthOrBusinessFailureNeverBecomesEmptySuccess() throws {
        let success = Data(#"{"code":10000,"data":{"records":[]}}"#.utf8)
        let rejected = Data(#"{"code":30000,"data":{"records":[]}}"#.utf8)
        XCTAssertTrue(try CatalogAPI.decodePage(success, status: 200).isEmpty)
        XCTAssertThrowsError(try CatalogAPI.decodePage(success, status: 403))
        XCTAssertThrowsError(try CatalogAPI.decodePage(rejected, status: 200))
    }

    @MainActor
    func testPaginationDeduplicatesAndStopsAtShortPage() async throws {
        let all = try fixtureShops(0...10)
        let defaultsName = "QidianCatalogTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let model = CatalogModel(defaults: defaults) { page, _ in
            page == 1 ? Array(all.prefix(10)) : Array(all.suffix(2))
        }
        await model.reload(keyword: "")
        XCTAssertEqual(model.shops.count, 10)
        XCTAssertTrue(model.hasMore)
        await model.loadMore()
        XCTAssertEqual(model.shops.map(\.id), all.map(\.id))
        XCTAssertFalse(model.hasMore)
    }

    @MainActor
    func testLateSearchResultDoesNotReplaceCurrentQuery() async throws {
        let shops = try fixtureShops(1...2)
        let stub = SearchStub(old: shops[0], new: shops[1])
        let suite = "QidianCatalogTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = CatalogModel(defaults: defaults) { _, keyword in await stub.fetch(keyword) }

        let first = Task { await model.reload(keyword: "旧结果") }
        await stub.waitUntilOldRequestStarts()
        await model.reload(keyword: "新结果")
        await stub.releaseOldRequest()
        await first.value
        XCTAssertEqual(model.activeKeyword, "新结果")
        XCTAssertEqual(model.shops.map(\.id), [shops[1].id])
    }

    @MainActor
    func testFavoritePersistsAndCanBeRemoved() throws {
        let shop = try XCTUnwrap(fixtureShops(1...1).first)
        let suite = "QidianCatalogTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = CatalogModel(defaults: defaults) { _, _ in [] }
        model.toggleFavorite(shop)
        let reopened = CatalogModel(defaults: defaults) { _, _ in [] }
        XCTAssertTrue(reopened.isFavorite(shop))
        reopened.toggleFavorite(shop)
        XCTAssertTrue(reopened.favorites.isEmpty)
    }

    private func fixtureShops(_ range: ClosedRange<Int>) throws -> [Shop] {
        let rows = range.map { ["id": String($0), "storeName": "示例店 \($0)"] }
        let data = try JSONSerialization.data(withJSONObject: rows)
        return try JSONDecoder().decode([Shop].self, from: data)
    }
}

private actor SearchStub {
    let old: Shop
    let new: Shop
    var pending: CheckedContinuation<[Shop], Never>?
    var started: CheckedContinuation<Void, Never>?

    init(old: Shop, new: Shop) {
        self.old = old
        self.new = new
    }

    func fetch(_ keyword: String) async -> [Shop] {
        guard keyword == "旧结果" else { return [new] }
        return await withCheckedContinuation { continuation in
            pending = continuation
            started?.resume()
            started = nil
        }
    }

    func waitUntilOldRequestStarts() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func releaseOldRequest() {
        let continuation = pending
        pending = nil
        continuation?.resume(returning: [old])
    }
}
