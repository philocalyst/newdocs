// Sources/DocsKit/Scrapers/Scraper.swift
import Foundation
import Logging
import SwiftSoup

open class Scraper: Doc {
  public let baseURL: DocsURL
  public let rootURL: DocsURL
  public let rootPath: String?
  public let initialPaths: [String]
  public let options: ScraperOptions
  public let filterStack: FilterStack

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
    options: ScraperOptions = ScraperOptions(),
    logger: Logger = Logger(label: "Scraper")
  ) throws {
    self.baseURL = try DocsURL(baseURL)
    self.rootPath = rootPath
    self.initialPaths = initialPaths
    self.options = options
    self.filterStack = FilterStack()

    if let rootPath = rootPath, !rootPath.isEmpty && rootPath != "/" {
      self.rootURL = self.baseURL.joining(rootPath)
    } else {
      self.rootURL = self.baseURL
    }

    try super.init(
      name: name,
      slug: slug,
      type: type,
      version: version,
      release: release,
      links: links,
      logger: logger
    )
  }

  public var initialURLs: [String] {
    var urls = [rootURL.description]
    urls.append(contentsOf: initialPaths.map { urlFor(path: $0) })
    return urls
  }

  internal func urlFor(path: String) -> String {
    if path.isEmpty || path == "/" {
      return rootURL.description
    } else {
      return baseURL.joining(path).description
    }
  }

  override public func buildPage(id: String) async throws -> PageResult? {
    let response = try await requestOne(url: urlFor(path: id))
    return try await handleResponse(response)
  }

  override public func buildPages() async throws -> AsyncStream<PageResult> {
    AsyncStream<PageResult>(bufferingPolicy: .unbounded) { continuation in
      Task {
        var history = Set(self.initialURLs.map { $0.lowercased() })

        do {
          try await self.requestAll(urls: self.initialURLs) { response in
            // your per-page handler
            guard let page = try await self.handleResponse(response) else {
              return []
            }

            continuation.yield(page)

            // queue up any newly discovered URLs
            return page.internalURLs.filter {
              history.insert($0.lowercased()).inserted
            }
          }
        } catch {
          self.logger.error("Error in buildPages loop: \(error)")
        }

        continuation.finish()
      }
    }
  }

  // Abstract methods to be implemented by subclasses
  open func requestOne(url: String) async throws -> HTTPResponse {
    throw DocsError.setupError("requestOne must be implemented by subclass")
  }

  open func requestAll(urls: [String], handler: @escaping (HTTPResponse) async throws -> [String])
    async throws
  {
    throw DocsError.setupError("requestAll must be implemented by subclass")
  }

  open func shouldProcessResponse(_ response: HTTPResponse) -> Bool {
    return response.isSuccess && response.isHTML && baseURL.contains(try! DocsURL(response.url))
  }

  func handleResponse(_ response: HTTPResponse) async throws -> PageResult? {
    guard shouldProcessResponse(response) else { return nil }

    return try await instrument("process_response", metadata: ["url": response.url]) {
      return try await processResponse(response)
    }
  }

  private func processResponse(_ response: HTTPResponse) async throws -> PageResult {
    let parser = try HTMLParser(response.body)
    let context = FilterContext(
      baseURL: baseURL,
      currentURL: try DocsURL(response.url),
      rootURL: rootURL,
      rootPath: rootPath,
      version: version,
      release: release,
      links: links,
      initialPaths: initialPaths,
      logger: logger
    )

    let processedDocument = try filterStack.apply(to: parser.document, context: context)

    // Extract entries and other data from processed document
    let entries = try extractEntries(from: processedDocument, context: context)
    let internalURLs = try extractInternalURLs(from: processedDocument)

    return PageResult(
      path: context.subpath,
      storePath: context.slug,
      output: try processedDocument.html(),
      entries: entries,
      internalURLs: internalURLs
    )
  }

  private func extractEntries(from document: Document, context: FilterContext) throws -> [Entry] {
    // This would be implemented based on specific scraper needs
    // For now, return empty array
    return []
  }

  private func extractInternalURLs(from document: Document) throws -> [String] {
    // Extract internal URLs from processed document
    let links = try document.select("a[href]")
    var urls: [String] = []

    for link in links {
      let href = try link.attr("href")
      if !href.isEmpty && isInternalURL(href) {
        urls.append(href)
      }
    }

    return urls
  }

  private func isInternalURL(_ url: String) -> Bool {
    // Simple check for internal URLs
    return !url.hasPrefix("http") && !url.hasPrefix("#") && !url.hasPrefix("data:")
  }
}

// In Sources/NewDocs/Scrapers/Scraper.swift (or wherever you declared ScraperOptions)

public struct ScraperOptions {
  public var skip: [String]
  public var skipPatterns: [NSRegularExpression]
  public var only: [String]
  public var onlyPatterns: [NSRegularExpression]
  public var skipLinks: [String]
  public var fixedInternalUrls: Bool
  public var redirections: [String: String]
  public var rateLimit: Int?
  public let maxConcurrency: Int
  public let timeout: TimeInterval
  public let retryCount: Int

  public init(
    skip: [String] = [],
    skipPatterns: [NSRegularExpression] = [],
    only: [String] = [],
    onlyPatterns: [NSRegularExpression] = [],
    skipLinks: [String] = [],
    fixedInternalUrls: Bool = false,
    redirections: [String: String] = [:],
    rateLimit: Int? = nil,
    maxConcurrency: Int = 20,
    timeout: TimeInterval = 30,
    retryCount: Int = 3
  ) {
    self.skip = skip
    self.skipPatterns = skipPatterns
    self.only = only
    self.onlyPatterns = onlyPatterns
    self.skipLinks = skipLinks
    self.fixedInternalUrls = fixedInternalUrls
    self.redirections = redirections
    self.rateLimit = rateLimit
    self.maxConcurrency = maxConcurrency
    self.timeout = timeout
    self.retryCount = retryCount
  }
}
