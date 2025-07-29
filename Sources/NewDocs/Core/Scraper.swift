import Foundation
import Logging
import SwiftSoup

public enum ScraperSource {
  case local(directory: URL)
  case remote(
    rateLimit: Int? = nil,
    headers: [String: String] = ["User-Agent": "NewDocs"],
    params: [URLQueryItem] = [],
    forceGzip: Bool = false
  )
}

public protocol Scraper: Doc {
  var baseURL: DocsURL { get }
  var rootURL: DocsURL { get }
  var rootPath: String? { get }
  var initialPaths: [String] { get }
  var options: ScraperOptions { get }
  var source: ScraperSource { get }
  var htmlFilters: FilterStack { get }
  var textFilters: FilterStack { get }

  /// Primitive you must implement
  func fetch(_ url: String) async throws -> HTTPResponse

  func extractEntries(
    from document: Document,
    context: FilterContext
  ) throws -> [Entry]

  /// Default‐overrideable hooks
  func shouldProcessResponse(_ response: HTTPResponse) -> Bool
  func preprocessResponse(_ response: HTTPResponse) -> HTTPResponse
}

extension Scraper {
  /// Compute your full URLs from the configured sub‐paths
  public var initialURLs: [String] {
    var urls = [rootURL.description]
    urls.append(contentsOf: initialPaths.map { urlFor(path: $0) })
    return urls
  }

  public func urlFor(path: String) -> String {
    if path.isEmpty || path == "/" {
      return rootURL.description
    } else {
      return baseURL.joining(path).description
    }
  }

  /// Default: no extra preprocessing
  public func preprocessResponse(_ response: HTTPResponse) -> HTTPResponse {
    response
  }

  /// Default: semver + HTML + same‐origin
  public func shouldProcessResponse(_ response: HTTPResponse) -> Bool {
    guard response.isSuccess && response.isHTML else { return false }
    guard let u = try? DocsURL(response.url),
      baseURL.contains(u)
    else {
      return false
    }
    return true
  }

  /// The single stream of pages, run *sequentially* to avoid capturing `inout`
  public func buildPages() -> AsyncStream<PageResult> {
    AsyncStream<PageResult>(bufferingPolicy: .unbounded) { continuation in
      Task {
        var seen = Set<String>()
        var queue = initialURLs

        while !queue.isEmpty {
          let path = queue.removeFirst()
          let key = path.lowercased()
          guard seen.insert(key).inserted else { continue }

          do {
            let raw = try await fetch(path)
            let response = preprocessResponse(raw)
            guard shouldProcessResponse(response) else { continue }

            let page = try await processResponse(response)
            continuation.yield(page)

            // enqueue newly discovered URLs
            for next in page.internalURLs {
              let lower = next.lowercased()
              if seen.insert(lower).inserted {
                queue.append(next)
              }
            }
          } catch {
            logger.error("Error scraping \(path): \(error)")
          }
        }

        continuation.finish()
      }
    }
  }

  /// Shared logic to turn an HTTPResponse → PageResult
  private func processResponse(_ response: HTTPResponse) async throws
    -> PageResult
  {
    let parser = try HTMLParser(response.body)
    let context = FilterContext(
      baseURL: baseURL,
      currentURL: try DocsURL(response.url),
      rootURL: rootURL,
      rootPath: rootPath,
      links: links,
      initialPaths: initialPaths,
      logger: logger
    )

    // 1) run your HTML filters
    let htmlDoc = try htmlFilters.apply(to: parser.document, context: context)
    // 2) run your text filters (they can pluck out entries, internalURLs, etc.)
    let finalDoc = try textFilters.apply(to: htmlDoc, context: context)

    // 3) extract the results
    let entries = try extractEntries(from: finalDoc, context: context)
    let internalURLs = try extractInternalURLs(from: finalDoc)

    return PageResult(
      path: context.subpath,
      storePath: context.slug,
      output: try finalDoc.html(),
      entries: entries,
      internalURLs: internalURLs
    )
  }

  /// Default no‐op: filters should build up your entries in the pipeline data
  private func extractEntries(from document: Document, context: FilterContext)
    throws -> [Entry]
  {
    return []
  }

  private func extractInternalURLs(from document: Document) throws -> [String] {
    let aTags = try document.select("a[href]").array()
    return try aTags.compactMap { a in
      let href = try a.attr("href")
      guard !href.isEmpty, isInternalURL(href) else { return nil }
      return href
    }
  }

  private func isInternalURL(_ url: String) -> Bool {
    return !url.hasPrefix("http")
      && !url.hasPrefix("#")
      && !url.hasPrefix("data:")
  }
}
