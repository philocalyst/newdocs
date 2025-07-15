import Foundation

public struct ScraperOptions {
  public var skip: [String]
  public var skipPatterns: [NSRegularExpression]
  public var only: [String]
  public var onlyPatterns: [NSRegularExpression]
  public var skipLinks: [String]
  public var fixedInternalUrls: Bool
  public var redirections: [String: String]
  public var rateLimit: Int?
  public var maxConcurrency: Int
  public var timeout: TimeInterval
  public var retryCount: Int
  public var fixURLs: ((String) -> String)?
  public var attribution: String?
  public var version: String?
  public var release: String?
  public var links: [String: String]

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
    retryCount: Int = 3,
    fixURLs: ((String) -> String)? = nil,
    attribution: String? = nil,
    version: String? = nil,
    release: String? = nil,
    links: [String: String] = [:]
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
    self.fixURLs = fixURLs
    self.attribution = attribution
    self.version = version
    self.release = release
    self.links = links
  }
}
