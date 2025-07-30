// Filtering for an HTML document, meant to be used to reduce unwanted structure.
// Think ads, nesting, etc. Basically an interface to build helpers ontop of,
// to pare down a messy document. Allows us to create simple methods that are universally useful,
// Like normalizing URLS :)

import Foundation
import Logging
import SwiftSoup

public protocol Filter {
  func apply(to document: Document, context: FilterContext) throws -> Document
}

public struct FilterContext {
  public let baseURL: URL
  public let currentURL: URL
  public let rootURL: URL
  public let rootPath: String?
  public let links: [String: URL]
  public let initialPaths: [URL]
  public let logger: Logger

  public init(
    baseURL: URL,
    currentURL: URL,
    rootURL: URL,
    rootPath: String? = nil,
    links: [String: URL] = [:],
    initialPaths: [URL] = [],
    logger: Logger = Logger(label: "Filter")
  ) {
    self.baseURL = baseURL
    self.currentURL = currentURL
    self.rootURL = rootURL
    self.rootPath = rootPath
    self.links = links
    self.initialPaths = initialPaths
    self.logger = logger
  }

  public var subpath: String {
    return baseURL.subpath(to: currentURL, ignoreCase: true) ?? ""
  }

  public var slug: String {
    let path = subpath.hasPrefix("/") ? String(subpath.dropFirst()) : subpath
    return path.replacingOccurrences(of: ".html", with: "")
  }

  public var isRootPage: Bool {
    return subpath.isEmpty || subpath == "/" || subpath == rootPath
  }

  public var isInitialPage: Bool {
    return isRootPage
      || initialPaths.contains(where: { $0.path == subpath })
  }
}

public protocol FilterStacking {
  mutating func push(_ filter: Filter)
  func apply(to document: Document, context: FilterContext) throws -> Document
}

public struct FilterStack: FilterStacking {
  private var filters: [Filter] = []

  public init() {}

  public mutating func push(_ filter: Filter) {
    filters.append(filter)
  }

  public func apply(to document: Document, context: FilterContext) throws
    -> Document
  {
    var currentDocument = document
    for filter in filters {
      currentDocument = try filter.apply(to: currentDocument, context: context)
    }
    return currentDocument
  }
}
