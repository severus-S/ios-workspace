import Foundation
import Observation

@MainActor
@Observable
final class CatalogModel {
    typealias FetchPage = @Sendable (Int, String) async throws -> [Shop]

    private(set) var shops: [Shop] = []
    private(set) var favorites: [Shop]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasMore = false
    private(set) var errorMessage: String?
    private(set) var activeKeyword = ""

    private static let favoritesKey = "qidianfood.savedShops.v1"
    private let defaults: UserDefaults
    private let fetchPage: FetchPage
    private var nextPage = 1
    private var failedPage = 1
    private var revision = 0

    init(defaults: UserDefaults = .standard, fetchPage: FetchPage? = nil) {
        self.defaults = defaults
        if let fetchPage {
            self.fetchPage = fetchPage
        } else {
            let api = CatalogAPI()
            self.fetchPage = { page, keyword in try await api.shops(page: page, keyword: keyword) }
        }
        if let snapshot = defaults.data(forKey: Self.favoritesKey),
           let saved = try? JSONDecoder().decode([Shop].self, from: snapshot) {
            favorites = saved
        } else {
            favorites = []
        }
    }

    func reload(keyword: String, debounce: Bool = false) async {
        revision += 1
        if activeKeyword != keyword {
            activeKeyword = keyword
            shops = []
            hasLoaded = false
            hasMore = false
            nextPage = 1
        }
        await request(page: 1, debounce: debounce)
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        await request(page: nextPage, debounce: false)
    }

    func retry(keyword: String) async {
        if failedPage > 1, keyword == activeKeyword {
            await loadMore()
        } else {
            await reload(keyword: keyword)
        }
    }

    func isFavorite(_ shop: Shop) -> Bool {
        favorites.contains { $0.id == shop.id }
    }

    func toggleFavorite(_ shop: Shop) {
        var updated = favorites
        if let index = updated.firstIndex(where: { $0.id == shop.id }) {
            updated.remove(at: index)
        } else {
            updated.insert(shop, at: 0)
        }
        if let snapshot = try? JSONEncoder().encode(updated) {
            defaults.set(snapshot, forKey: Self.favoritesKey)
            favorites = updated
        }
    }

    private func request(page: Int, debounce: Bool) async {
        let token = revision
        let keyword = activeKeyword
        isLoading = true
        errorMessage = nil
        defer {
            if token == revision { isLoading = false }
        }

        do {
            if debounce { try await Task.sleep(for: .milliseconds(350)) }
            let pageShops = try await fetchPage(page, keyword)
            try Task.checkCancellation()
            guard token == revision else { return }

            let current = page == 1 ? [] : shops
            var seen = Set(current.map(\.id))
            let additions = pageShops.filter { seen.insert($0.id).inserted }
            shops = current + additions
            hasLoaded = true
            hasMore = pageShops.count >= CatalogAPI.pageSize && !additions.isEmpty
            nextPage = page + 1
        } catch {
            guard token == revision, !Task.isCancelled, !(error is CancellationError) else { return }
            failedPage = page
            errorMessage = (error as? CatalogError)?.errorDescription ?? "暂时无法读取商家，请检查网络后重试。"
        }
    }
}
