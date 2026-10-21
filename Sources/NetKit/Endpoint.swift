import Foundation

public enum HTTPMethod: String {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

/// Strongly-typed description of a REST endpoint.
/// The `Response` generic ties the endpoint to the type it decodes into,
/// so the client can return a strongly-typed value without casts.
public struct Endpoint<Response: Decodable> {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: Data?

    public init(method: HTTPMethod = .get,
                path: String,
                queryItems: [URLQueryItem] = [],
                headers: [String: String] = [:],
                body: Data? = nil) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}
