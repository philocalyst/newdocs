// Sources/NewDocs/Scrapers/Unified.swift

import Alamofire
import Foundation
import Logging

/// Simple actor to throttle remote requests to `limit` per minute.
actor RateLimiter {
  private let limit: Int
  private var timestamps: [Date] = []

  init(limit: Int) {
    self.limit = limit
  }

  /// Suspends the current task until we're under `limit` requests/minute again.
  func waitIfNeeded() async {
    let now = Date()
    let oneMinuteAgo = now.addingTimeInterval(-60)

    // drop old timestamps
    timestamps.removeAll { $0 <= oneMinuteAgo }

    if timestamps.count >= limit, let oldest = timestamps.first {
      let waitTime = 60 - now.timeIntervalSince(oldest) + 1
      if waitTime > 0 {
        try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
      }
    }

    timestamps.append(now)
  }
}

/// Denotes whether we fetch pages from disk or from HTTP.
public enum ScraperSource {
  case local(directory: String)
  case remote(
    rateLimit: Int? = nil,
    headers: HTTPHeaders = ["User-Agent": "DocsKit"],
    params: [String: Any] = [:],
    forceGzip: Bool = false
  )
}

/// A single class that can do both file-based and URL-based scraping.
open class UnifiedScraper: Scraper {
  public let source: ScraperSource
  private let httpRequest: HTTPRequest
  private let rateLimiter: RateLimiter?

  public init(
    name: String,
    slug: String,
    type: String,
    baseURL: String,
    rootPath: String? = nil,
    initialPaths: [String] = [],
    version: String? = nil,
    release: String? = nil,
    links: [String: String] = [:],
    source: ScraperSource,
    options: ScraperOptions = ScraperOptions(),
    logger: Logger = .init(label: "UnifiedScraper")
  ) throws {
    self.source = source
    self.httpRequest = HTTPRequest(logger: logger)

    // If remote + rateLimit, make a limiter; otherwise nil
    switch source {
    case .local:
      self.rateLimiter = nil

      // ensure directory exists
      let dir = {
        if case let .local(d) = source { return d }
        return ""
      }()
      guard FileManager.default.fileExists(atPath: dir) else {
        throw DocsError.setupError("Local source dir not found: \(dir)")
      }

    case .remote(let rateLimit, _, _, _):
      self.rateLimiter = rateLimit.map { RateLimiter(limit: $0) }
    }

    try super.init(
      name: name,
      slug: slug,
      type: type,
      baseURL: baseURL,
      rootPath: rootPath,
      initialPaths: initialPaths,
      version: version,
      release: release,
      links: links,
      options: options,
      logger: logger
    )
  }

  // MARK: - Single-Page Fetching

  override public func requestOne(url: String) async throws -> HTTPResponse {
    switch source {

    case .local(let directory):
      let rel = url.replacingOccurrences(of: baseURL.description, with: "")
      let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(rel)

      do {
        let html = try String(contentsOf: fileURL, encoding: .utf8)
        return HTTPResponse(
          url: url,
          statusCode: 200,
          headers: ["Content-Type": "text/html"],
          data: html.data(using: .utf8) ?? Data()
        )
      } catch {
        logger.warning("Failed to read \(fileURL.path): \(error)")
        return HTTPResponse(url: url, statusCode: 404, headers: [:], data: Data())
      }

    case .remote(let rateLimit, let headers, let params, let forceGzip):
      if let limiter = rateLimiter {
        await limiter.waitIfNeeded()
      }
      var reqHeaders = headers
      if forceGzip {
        reqHeaders.add(name: "Accept-Encoding", value: "gzip")
      }
      return try await httpRequest.request(
        url,
        parameters: params,
        headers: reqHeaders
      )
    }
  }

  // MARK: - Multi-Page Fetching

  /// Builds an AsyncStream of PageResult by repeatedly calling `requestOne`/`handler`.
  override public func buildPages() async throws -> AsyncStream<PageResult> {
    AsyncStream<PageResult>(bufferingPolicy: .unbounded) { continuation in
      Task {
        var history = Set(self.initialURLs.map { $0.lowercased() })

        do {
          try await self.requestAll(urls: self.initialURLs) { response in
            guard let page = try await self.handleResponse(response) else {
              return []
            }
            continuation.yield(page)

            let next = page.internalURLs.filter {
              history.insert($0.lowercased()).inserted
            }

            return next
          }
        } catch {
          self.logger.error("Error in buildPages loop: \(error)")
        }

        continuation.finish()
      }
    }
  }
}
