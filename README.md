## Open and build

Open `NetKit.xcodeproj` in Xcode and select the shared `NetKit` scheme. The iOS targets require iOS 17.0 or later. Select your development team for physical device deployment; shared entitlements may also require registering the App Group in your account.

The Swift Package remains the source distribution. The Xcode framework target includes a hostless test target; run `swift test` for the existing offline networking tests.

```bash
xcodebuild -project NetKit.xcodeproj -scheme NetKit -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Repository organization

Swift files stay under `Sources/` with Xcode groups matching the physical folders. Assets and entitlements are under `Resources/`. Libraries retain `Package.swift`; their demo and tests have separate target membership. Shared schemes are committed; personal Xcode state and build outputs are ignored. The app icon catalog contains a slot for final artwork.

This repository is private. Swift Package consumers must authenticate with GitHub. Use the `main` branch until a versioned release is created.

<div align="center">

# 📦 NetKit

### A lightweight, type-safe, actor-based networking layer for iOS. Published as a Swift Package.

![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)
![SPM](https://img.shields.io/badge/SwiftPM-✓-green?style=for-the-badge&logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/iOS%2016%2B%20%7C%20macOS%2013%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)

</div>

---

## ✨ Overview

**NetKit** is a tiny, reusable networking layer designed for production iOS apps. It packs everything you need — type-safe endpoints, actor-isolation for thread safety, pluggable interceptors, structured errors — and nothing you don't. Drop it into any app via Swift Package Manager.

This is your **open-source library** repo — perfect signal that you write reusable code, not just app code.

---

## 🚀 Features

- 🔒 **Type-safe `Endpoint<Response>`** — compiler-enforced response type
- 🧵 **Actor-isolated `HTTPClient`** — thread-safe by construction
- 🔌 **Pluggable interceptors** — auth, logging, retry, telemetry
- 🚨 **Typed errors** — `invalidURL`, `transport`, `decoding`, `httpStatus`
- ✅ Built-in **Bearer token** interceptor
- 📜 Built-in **OSLog** interceptor for debugging
- 🧪 **100% testable** via `URLProtocol`-based stubs (no third-party mocks)
- 📦 Zero dependencies — pure Foundation + URLSession

---

## 📦 Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/sachinarkasali944/NetKit.git", branch: "main")
```

Or in Xcode: `File → Add Package Dependencies…` → paste the GitHub URL.

---

## 🚀 Quick Start

```swift
import NetKit

// 1. Define a response model
struct GitHubUser: Decodable {
    let id: Int; let login: String
}

// 2. Create a client (typically once, app-wide)
let client = HTTPClient(
    baseURL: URL(string: "https://api.github.com")!,
    interceptors: [
        BearerTokenInterceptor { await TokenStore.shared.current },
        LoggingInterceptor()
    ]
)

// 3. Send a strongly-typed request
let endpoint = Endpoint<GitHubUser>(path: "/users/octocat")
let user = try await client.send(endpoint)
```

---

## 🏗️ Architecture

```
Client code
   │
   │   Endpoint<User>   ─── strongly typed
   ▼
HTTPClient (actor)
   │
   ├─ apply each Interceptor (auth, logging, retry…)
   │
   └─ URLSession.data(for:)  →  decode  →  Response
```

---

## 🧪 Testing

NetKit uses a minimal `URLProtocol`-based stub for fully offline tests — no third-party mocking libraries.

```swift
URLProtocolStub.requestHandler = { request in
    let response = HTTPURLResponse(
        url: request.url!, statusCode: 200,
        httpVersion: nil, headerFields: nil
    )!
    let data = #"{"message":"hi"}"#.data(using: .utf8)!
    return (response, data)
}
```

Run all tests:

```bash
swift test
```

---

## 📂 Project Structure

```
NetKit/
├── Package.swift
├── Sources/NetKit/
│   ├── Endpoint.swift          # Endpoint<Response>, HTTPMethod
│   ├── HTTPClient.swift        # actor HTTPClient + NetKitError
│   └── Interceptors.swift      # BearerTokenInterceptor, LoggingInterceptor
└── Tests/NetKitTests/
    └── HTTPClientTests.swift   # URLProtocol-based stubs
```

---

## 🧩 Design decisions (interview gold)

- **Why `actor`?** Centralised mutable state (session, decoder, interceptors) is protected from data races by the compiler.
- **Why generic `Endpoint<Response>`?** The compiler enforces "this endpoint returns this type"; no casts in client code.
- **Why protocol-based interceptors?** Anyone can write a `RetryInterceptor`, `OfflineCacheInterceptor`, etc., without modifying NetKit.
- **Why no Combine?** async/await is the future and avoids Combine's memory-management pitfalls.
- **Why no third-party deps?** Easy to audit, easy to update, no transitive risk.

---

## 🛣️ Roadmap

- [ ] `RetryInterceptor` with exponential backoff
- [ ] `OfflineCacheInterceptor` backed by URLCache
- [ ] Multipart upload helper
- [ ] WebSocket helper using `URLSessionWebSocketTask`
- [ ] Code-gen plugin from OpenAPI spec

---

## 📄 License

MIT — see [LICENSE](LICENSE).

## 👨‍💻 Author

**Sachin Arkasali** · [GitHub](https://github.com/sachinarkasali944) · [LinkedIn](https://linkedin.com/in/sachinarkasali)
