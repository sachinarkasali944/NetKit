import Foundation
import OSLog

public struct BearerTokenInterceptor: RequestInterceptor {
    let tokenProvider: () async -> String?

    public init(tokenProvider: @escaping () async -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(_ request: inout URLRequest) async throws {
        if let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}

public struct LoggingInterceptor: RequestInterceptor {
    private let logger = Logger(subsystem: "NetKit", category: "http")
    public init() {}
    public func intercept(_ request: inout URLRequest) async throws {
        let method = request.httpMethod ?? "?"
        let path = request.url?.path ?? "?"
        logger.debug("→ \(method) \(path)")
    }
}
