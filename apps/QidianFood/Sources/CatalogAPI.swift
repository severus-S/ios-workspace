import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Shop: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let category: String?
    let imagePath: String?
    let minimumAmount: Decimal?

    private enum CodingKeys: String, CodingKey {
        case id
        case name = "storeName"
        case category = "classifyName"
        case imagePath = "storeImagePath"
        case minimumAmount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !name.isEmpty else {
            throw CatalogError.invalidResponse
        }
        category = try? values.decode(String.self, forKey: .category).trimmingCharacters(in: .whitespacesAndNewlines)
        imagePath = try? values.decode(String.self, forKey: .imagePath)
        minimumAmount = try? values.decode(Decimal.self, forKey: .minimumAmount)
    }

    var imageURL: URL? {
        guard let imagePath, let components = URLComponents(string: imagePath),
              components.scheme?.lowercased() == "https",
              components.host?.lowercased() == "oss.hebooming.com",
              components.user == nil, components.password == nil,
              components.port == nil || components.port == 443 else { return nil }
        return components.url
    }

    var positiveMinimum: Decimal? {
        guard let minimumAmount, minimumAmount > 0 else { return nil }
        return minimumAmount
    }
}

enum CatalogError: LocalizedError {
    case authenticationRequired
    case busy
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .authenticationRequired: return "商家目录暂时无法匿名访问。"
        case .busy: return "商家目录暂时繁忙，请稍后重试。"
        case .invalidResponse: return "没有收到可用的商家数据，请重试。"
        }
    }
}

struct CatalogAPI: Sendable {
    static let campusID = "1369455724900470786"
    static let campusName = "辽宁大学蒲河校区"
    static let pageSize = 10

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        session = URLSession(configuration: configuration, delegate: GuestSessionDelegate(), delegateQueue: nil)
    }

    func shops(page: Int, keyword: String) async throws -> [Shop] {
        let (data, response) = try await session.data(for: Self.request(page: page, keyword: keyword))
        guard let response = response as? HTTPURLResponse else { throw CatalogError.invalidResponse }
        return try Self.decodePage(data, status: response.statusCode)
    }

    static func request(page: Int, keyword: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://icsp.hebooming.com:8081/takeout/store/open/page")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ShopQuery(campusId: campusID, current: page, size: pageSize, keywords: keyword.isEmpty ? nil : keyword)
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    static func decodePage(_ data: Data, status: Int) throws -> [Shop] {
        switch status {
        case 401, 403: throw CatalogError.authenticationRequired
        case 429, 500...599: throw CatalogError.busy
        case 200: break
        default: throw CatalogError.invalidResponse
        }
        guard data.count <= 1_048_576 else { throw CatalogError.invalidResponse }
        return try JSONDecoder().decode(ShopResponse.self, from: data).records
    }
}

private struct ShopQuery: Encodable {
    let app = "QDMS"
    let platformName = "QDMS"
    let campusId: String
    let current: Int
    let size: Int
    let keywords: String?
}

private struct ShopResponse: Decodable {
    let records: [Shop]

    private enum CodingKeys: String, CodingKey { case code, data }
    private struct Page: Decodable { let records: [Shop] }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let code = try? values.decode(Int.self, forKey: .code)
        let text = try? values.decode(String.self, forKey: .code)
        guard code == 10_000 || text == "10000" else { throw CatalogError.invalidResponse }
        records = try values.decode(Page.self, forKey: .data).records
    }
}

private final class GuestSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
