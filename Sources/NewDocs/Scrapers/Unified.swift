// Sources/DocsKit/Scrapers/UnifiedScraper.swift

import Alamofire
import Foundation
import Logging

public enum ScraperSource {
  case local(directory: String)
  case remote(
    rateLimit: Int? = nil,
    headers: HTTPHeaders = ["User-Agent": "DocsKit"],
    params: [String: Any] = [:],
    forceGzip: Bool = false
  )
}

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
    logger: Logger = Logger(label: "UnifiedScraper")
  ) throws {
    self.source = source
    self.httpRequest = HTTPRequest(logger: logger)
    // if remote & rateLimit given, build a rate‐limiter
    switch source {
    case .remote(let rateLimit, _, _, _):
      self.rateLimiter = rateLimit.map { RateLimiter(limit: $0) }
    case .local:
      self.rateLimiter = nil
    }

    // If local, verify the directory exists
    if case let .local(dir) = source {
      guard FileManager.default.fileExists(atPath: dir) else {
        throw DocsError.setupError("Local source directory not found: \(dir)")
      }
    }

    try super.init(
      name: name, slug: slug, type: type,
      baseURL: baseURL, rootPath: rootPath,
      initialPaths: initialPaths, version: version,
      release: release, links: links,
      options: options, logger: logger
    )
  }

  // MARK: – Request Single Page

  override public func requestOne(url: String) async throws -> HTTPResponse {
    switch source {
    case .local(let directory):
      // Turn URL path into filesystem path
      let relative = url.replacingOccurrences(of: baseURL.description, with: "")
      let fileURL = URL(fileURLWithPath: directory)
        .appendingPathComponent(relative)
      do {
        let html = try String(contentsOf: fileURL, encoding: .utf8)
        return HTTPResponse(
          url: url, statusCode: 200,
          headers: ["Content-Type": "text/html"],
          data: html.data(using: .utf8) ?? Data()
        )
      } catch {
        logger.warning("Failed to read \(fileURL.path): \(error)")
        return HTTPResponse(
          url: url, statusCode: 404,
          headers: [:], data: Data()
        )
      }

    case .remote(_, let headers, let params, let forceGzip):
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

  // MARK: – Request Many Pages

  override public func requestAll(
    urls: [String],
    handler: @escaping (HTTPResponse) async throws -> [String]
  ) async throws {
    switch source {
    case .local:
      // same logic as FileScraper
      var queue = urls
      while !queue.isEmpty {
        let url = queue.removeFirst()
        let resp = try await requestOne(url: url)
        let next = try await handler(resp)
        queue.append(contentsOf: next)
      }

    case .remote:
      // same logic as URLScraper
      var queue = urls
      var active = 0
      let maxC = options.maxConcurrency

      while !queue.isEmpty || active > 0 {
        while active < maxC && !queue.isEmpty {
          let url = queue.removeFirst()
          active += 1
          Task {
            defer { active -= 1 }
            do {
              if let limiter = rateLimiter {
                await limiter.waitIfNeeded()
              }
              let resp = try await requestOne(url: url)
              let next = try await handler(resp)
              queue.append(contentsOf: next)
            } catch {
              logger.error("Error scraping \(url): \(error)")
            }
          }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
      }
    }
  }

}
