import Foundation
import Logging
import SwiftSoup

public enum ScraperSource {
  case local(directory: URL)
  case remote(
    rateLimit: Int? = nil,
    headers: [String: String] = ["User-Agent": "NewDocumentations"],
    params: [URLQueryItem] = [],
    forceGzip: Bool = false
  )
}

public protocol Scraper: Documentation {
  var baseURL: URL { get }
  var rootURL: URL { get }
  var rootPath: String? { get }
  var initialPaths: [URL] { get }
  var options: ScraperOptions { get }
  var source: ScraperSource { get }
  var htmlFilters: FilterStack { get }
  var textFilters: FilterStack { get }

  /// Primitive you must implement
  func fetch(_ url: URL) async throws -> HTTPResponse

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
  public var initialURLs: [URL] {
    var urls = [rootURL]
    urls.append(contentsOf: initialPaths.map { $0 })
    return urls
  }

  public func urlFor(path: String) -> URL {
    if path.isEmpty || path == "/" {
      return rootURL
    } else {
      return baseURL.appending(path: path)
    }
  }

  /// Default: no extra preprocessing
  public func preprocessResponse(_ response: HTTPResponse) -> HTTPResponse {
    response
  }

  /// Default: semver + HTML + same‐origin
  public func shouldProcessResponse(_ response: HTTPResponse) -> Bool {
    guard response.isSuccess && response.isHTML else { return false }

    // Skip redirects and not found pages
    if response.body.contains("http-equiv=\"refresh\"")
      || response.body.contains("<title>Not Found</title>") || response.body.isEmpty
    {
      return false
    }

    // Check if URL is within our base domain/path
    guard let responseURL = URL(string: response.url) else { return false }

    // For rust-reference, allow anything under doc.rust-lang.org/
    if self.slug == "rust-reference" {
      let should =
        responseURL.host == baseURL.host
        && responseURL.absoluteString.hasPrefix(baseURL.absoluteString)

      return should
    }

    // For std, allow anything under doc.rust-lang.org/
    if self.slug == "std" {
      return responseURL.host == baseURL.host
        && responseURL.absoluteString.hasPrefix(baseURL.absoluteString)
    }

    // For regular crates, check docs.rs prefix
    return responseURL.absoluteString.hasPrefix(baseURL.absoluteString)
  }

  /// The single stream of pages, run *sequentially* to avoid capturing `inout`
  public func buildPages() -> AsyncThrowingStream<DocumentationPage, Error> {
    AsyncThrowingStream<DocumentationPage, Error>(bufferingPolicy: .unbounded) { continuation in
      Task {
        var seen = Set<URL>()
        var queue = initialURLs

        while !queue.isEmpty {
          let path = queue.removeFirst()
          guard seen.insert(path).inserted else { continue }

          do {
            let raw = try await fetch(path)
            let response = preprocessResponse(raw)
            guard shouldProcessResponse(response) else { continue }

            let page = try await processResponse(response)
            continuation.yield(page)

            // enqueue newly discovered URLs
            for url in page.internalURLs {
              if !seen.contains(url) {
                queue.append(url)
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
    -> DocumentationPage
  {
    let parser = try HTMLParser(response.body)
    let context = FilterContext(
      baseURL: baseURL,
      currentURL: URL(string: response.url)!,
      rootURL: rootURL,
      rootPath: rootPath,
      links: links,
      initialPaths: initialPaths,
      logger: logger
    )

    // 1) run your HTML filters
    let htmlDocumentation = try htmlFilters.apply(to: parser.document, context: context)
    // 2) run your text filters (they can pluck out entries, internalURLs, etc.)
    let finalDocumentation = try textFilters.apply(to: htmlDocumentation, context: context)

    // 3) extract the results
    let entries = try extractEntries(from: finalDocumentation, context: context)
    let internalURLs = try extractInternalURLs(from: finalDocumentation)

    return DocumentationPage(
      path: context.subpath,
      content: try finalDocumentation.html(),
      internalURLs: internalURLs,
      entries: entries,
    )
  }

  /// Default no‐op: filters should build up your entries in the pipeline data
  private func extractEntries(from document: Document, context: FilterContext)
    throws -> [Entry]
  {
    return []
  }

  private func extractInternalURLs(from document: Document) throws -> [URL] {
    let aTags = try document.select("a[href]").array()
    return try aTags.compactMap { a in
      let href = try a.attr("href")
      guard !href.isEmpty, isInternalURL(href) else { return nil }
      return URL(string: href, relativeTo: baseURL)?.absoluteURL
    }
  }

  private func isInternalURL(_ url: String) -> Bool {
    return !url.hasPrefix("http")
      && !url.hasPrefix("#")
      && !url.hasPrefix("data:")
  }
}
