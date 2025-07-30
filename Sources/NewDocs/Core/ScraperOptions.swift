import Foundation

public final class ScraperOptions {
  public var skip: [String] = []
  public var skipPatterns: [NSRegularExpression] = []
  public var only: [String] = []
  public var onlyPatterns: [NSRegularExpression] = []
  public var skipLinks: [String] = []
  public var fixedInternalUrls: Bool = false
  public var redirections: [String: String] = [:]
  public var rateLimit: Int?
  public var maxConcurrency: Int = 20
  public var timeout: TimeInterval = 30
  public var retryCount: Int = 3
  public var fixURLs: ((String) -> String)?
  public var attribution: String?
  public var version: String?
  public var release: String?
  public var links: [String: String] = [:]

  @discardableResult
  public func withSkip(_ skip: [String]) -> Self {
    self.skip = skip

    return self
  }

  @discardableResult
  public func withSkipPatterns(_ skipPatterns: [NSRegularExpression]) -> Self {
    self.skipPatterns = skipPatterns
    return self
  }

  @discardableResult
  public func withOnly(_ only: [String]) -> Self {
    self.only = only
    return self
  }

  @discardableResult
  public func withOnlyPatterns(_ onlyPatterns: [NSRegularExpression]) -> Self {
    self.onlyPatterns = onlyPatterns
    return self
  }

  @discardableResult
  public func withSkipLinks(_ skipLinks: [String]) -> Self {
    self.skipLinks = skipLinks
    return self
  }

  @discardableResult
  public func withFixedInternalUrls(_ fixedInternalUrls: Bool) -> Self {
    self.fixedInternalUrls = fixedInternalUrls
    return self
  }

  @discardableResult
  public func withRedirections(_ redirections: [String: String]) -> Self {
    self.redirections = redirections
    return self
  }

  @discardableResult
  public func withRateLimit(_ rateLimit: Int?) -> Self {
    self.rateLimit = rateLimit
    return self
  }

  @discardableResult
  public func withMaxConcurrency(_ maxConcurrency: Int) -> Self {
    self.maxConcurrency = maxConcurrency
    return self
  }

  @discardableResult
  public func withTimeout(_ timeout: TimeInterval) -> Self {
    self.timeout = timeout
    return self
  }

  @discardableResult
  public func withRetryCount(_ retryCount: Int) -> Self {
    self.retryCount = retryCount
    return self
  }

  @discardableResult
  public func withFixURLs(_ fixURLs: ((String) -> String)?) -> Self {
    self.fixURLs = fixURLs
    return self
  }

  @discardableResult
  public func withAttribution(_ attribution: String?) -> Self {
    self.attribution = attribution
    return self
  }

  @discardableResult
  public func withVersion(_ version: String?) -> Self {
    self.version = version
    return self
  }

  @discardableResult
  public func withRelease(_ release: String?) -> Self {
    self.release = release
    return self
  }

  @discardableResult
  public func withLinks(_ links: [String: String]) -> Self {
    self.links = links
    return self
  }

  public init() {}
}
