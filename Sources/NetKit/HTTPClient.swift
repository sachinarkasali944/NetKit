import Foundation

public enum NetKitError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case decoding(String)
    case httpStatus(Int, Data?)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:            return "The URL could not be constructed."
        case .transport(let msg):    return "Network error: \(msg)"
        case .decoding(let msg):     return "Decoding failed: \(msg)"
        case .httpStatus(let code, _): return "Server returned HTTP \(code)."
        }
    }

    public static func == (lhs: NetKitError, rhs: NetKitError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case let (.transport(a), .transport(b)): return a == b
        case let (.decoding(a), .decoding(b)): return a == b
        case let (.httpStatus(a, _), .httpStatus(b, _)): return a == b
        default: return false
        }
    }
}

/// Pluggable request interceptor (auth, telemetry, retries, etc.).
public protocol RequestInterceptor {
    func intercept(_ request: inout URLRequest) async throws
}

public actor HTTPClient {
    public let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let interceptors: [RequestInterceptor]

    public init(baseURL: URL,
                session: URLSession = .shared,
                decoder: JSONDecoder = JSONDecoder(),
                interceptors: [RequestInterceptor] = []) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.interceptors = interceptors
    }

    public func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response {
        var components = URLComponents(url: baseURL.appending(path: endpoint.path),
                                       resolvingAgainstBaseURL: false)
        if !endpoint.queryItems.isEmpty { components?.queryItems = endpoint.queryItems }
        guard let url = components?.url else { throw NetKitError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        for interceptor in interceptors {
            try await interceptor.intercept(&request)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetKitError.transport("Invalid response object")
            }
            guard (200...299).contains(http.statusCode) else {
                throw NetKitError.httpStatus(http.statusCode, data)
            }
            if Response.self == EmptyResponse.self {
                return EmptyResponse() as! Response
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw NetKitError.decoding(error.localizedDescription)
            }
        } catch let error as NetKitError {
            throw error
        } catch {
            throw NetKitError.transport(error.localizedDescription)
        }
    }
}

public struct EmptyResponse: Decodable { public init() {} }
