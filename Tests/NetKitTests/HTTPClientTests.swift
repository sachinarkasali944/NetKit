import XCTest
@testable import NetKit

final class HTTPClientTests: XCTestCase {

    override func setUp() {
        URLProtocolStub.requestHandler = nil
    }

    private func makeSUT() -> HTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return HTTPClient(baseURL: URL(string: "https://api.test")!, session: session)
    }

    struct Echo: Decodable, Equatable { let message: String }

    func test_send_decodesResponseOn200() async throws {
        URLProtocolStub.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.test/echo")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            let data = #"{"message":"hi"}"#.data(using: .utf8)!
            return (response, data)
        }

        let client = makeSUT()
        let result: Echo = try await client.send(Endpoint(path: "/echo"))
        XCTAssertEqual(result, Echo(message: "hi"))
    }

    func test_send_throwsHttpStatusOn500() async {
        URLProtocolStub.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.test/echo")!,
                statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }
        let client = makeSUT()
        do {
            let _: Echo = try await client.send(Endpoint(path: "/echo"))
            XCTFail("Expected throw")
        } catch let error as NetKitError {
            XCTAssertEqual(error, .httpStatus(500, nil))
        } catch {
            XCTFail("Unexpected: \(error)")
        }
    }
}

// MARK: - URLProtocol stub
final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
