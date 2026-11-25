import SwiftUI
import UIKit

private enum CatalogRoute: Hashable {
    case favorites
    case shop(Shop)
}

@MainActor
struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var model = CatalogModel()
    @State private var searchText = ""

    private var keyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 0.49, green: 0.83, blue: 0.75)
            : Color(red: 0.03, green: 0.39, blue: 0.34)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    catalogContent
                } header: {
                    Label(CatalogAPI.campusName, systemImage: "location")
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
            .navigationTitle("蒲河食单")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索蒲河校区商家")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: CatalogRoute.favorites) {
                        Label("收藏商家", systemImage: "bookmark")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .navigationDestination(for: CatalogRoute.self) { route in
                switch route {
                case .favorites:
                    FavoritesView(model: model)
                case let .shop(shop):
                    ShopDetailView(shop: shop, model: model)
                }
            }
            .task(id: keyword) {
                let query = keyword
                await model.reload(keyword: query, debounce: !query.isEmpty)
            }
            .refreshable {
                await model.reload(keyword: keyword)
            }
        }
        .tint(accent)
    }

    @ViewBuilder
    private var catalogContent: some View {
        if model.activeKeyword != keyword || (model.shops.isEmpty && model.isLoading) {
            ProgressView(keyword.isEmpty ? "正在读取商家" : "正在搜索商家")
                .frame(maxWidth: .infinity, minHeight: 104)
                .listRowSeparator(.hidden)
        } else if let error = model.errorMessage, model.shops.isEmpty {
            ContentUnavailableView {
                Label("商家加载失败", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("重试") { Task { await model.retry(keyword: keyword) } }
                    .buttonStyle(.bordered)
            }
            .listRowSeparator(.hidden)
        } else if !model.hasLoaded {
            ProgressView("正在读取商家")
                .frame(maxWidth: .infinity, minHeight: 104)
                .listRowSeparator(.hidden)
        } else if model.shops.isEmpty {
            ContentUnavailableView(
                keyword.isEmpty ? "暂无商家" : "没有找到商家",
                systemImage: keyword.isEmpty ? "fork.knife" : "magnifyingglass",
                description: Text(keyword.isEmpty ? "可下拉刷新试试。" : "换个店名试试。")
            )
            .listRowSeparator(.hidden)
        } else {
            ForEach(model.shops) { shop in
                ShopLink(shop: shop, model: model)
            }
            if let error = model.errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("重试") { Task { await model.retry(keyword: keyword) } }
                        .frame(minHeight: 44, alignment: .leading)
                }
            } else if model.isLoading {
                ProgressView()
                    .accessibilityLabel("正在读取商家")
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else if model.hasMore {
                Button {
                    Task { await model.loadMore() }
                } label: {
                    Text("加载更多商家")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }
}

@MainActor
private struct ShopLink: View {
    let shop: Shop
    let model: CatalogModel

    var body: some View {
        NavigationLink(value: CatalogRoute.shop(shop)) {
            HStack(alignment: .center, spacing: 12) {
                ShopArtwork(url: shop.imageURL, size: 56, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let category = shop.category, !category.isEmpty {
                        Text(category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let amount = shop.positiveMinimum {
                        Text("\(amount.formatted(.currency(code: "CNY"))) 起送")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if model.isFavorite(shop) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .accessibilityLabel("已收藏")
                }
            }
            .padding(.vertical, 5)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                model.toggleFavorite(shop)
            } label: {
                Label(model.isFavorite(shop) ? "取消收藏" : "收藏", systemImage: "bookmark")
            }
        }
    }
}

@MainActor
private struct FavoritesView: View {
    let model: CatalogModel

    var body: some View {
        List(model.favorites) { shop in
            ShopLink(shop: shop, model: model)
        }
        .listStyle(.plain)
        .overlay {
            if model.favorites.isEmpty {
                ContentUnavailableView("还没有收藏", systemImage: "bookmark", description: Text("打开商家详情即可收藏。"))
            }
        }
        .navigationTitle("收藏商家")
    }
}

@MainActor
private struct ShopDetailView: View {
    let shop: Shop
    let model: CatalogModel
    @State private var copied = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ShopArtwork(url: shop.imageURL, size: 88, cornerRadius: 14)
                    Text(shop.name)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let category = shop.category, !category.isEmpty {
                        Text(category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let amount = shop.positiveMinimum {
                        LabeledContent("起送金额") {
                            Text(amount, format: .currency(code: "CNY"))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                Button {
                    model.toggleFavorite(shop)
                } label: {
                    Label(model.isFavorite(shop) ? "取消收藏" : "收藏商家", systemImage: model.isFavorite(shop) ? "bookmark.fill" : "bookmark")
                        .frame(minHeight: 44, alignment: .leading)
                }
                Button {
                    UIPasteboard.general.string = shop.name
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    copied = true
                } label: {
                    Label("复制店名", systemImage: "doc.on.doc")
                        .frame(minHeight: 44, alignment: .leading)
                }
            } footer: {
                Text("在微信内打开「奇点美食」，登录后搜索店名可查看菜单和下单。")
            }
        }
        .navigationTitle("商家详情")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: model.isFavorite(shop))
        .alert("已复制店名", isPresented: $copied) {
            Button("好", role: .cancel) { }
        }
    }
}

private struct ShopArtwork: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }
}
