// Contains the logic for the storing... Documentations!! This is going to handle the composition
// Of all of the important doc information... think index, meta, and content, into the
// formats they're expected to be.

import Foundation
import Logging

public protocol DocumentationStorerProtocol {
  func store(_ doc: Documentation, to store: DocumentStore) async throws
}

struct Meta: Encodable {
  var information: Documentation
  var index: EntryIndex

  enum CodingKeys: String, CodingKey {
    case information
    case index
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    let docInfo: [String: String] = [
      "slug": information.slug,
      "name": information.name,
      "version": information.version.versionString(),
    ]
    try container.encode(docInfo, forKey: .information)

    try container.encode(index, forKey: .index)
  }

  init(index: EntryIndex, information: Documentation) {
    self.index = index
    self.information = information
  }
}

/// The default implementation for doc storage
public struct DocumentationStorer: DocumentationStorerProtocol {
  private let logger: Logger

  public init(logger: Logger = Logger(label: "DocumentationStorer")) {
    self.logger = logger
  }

  public func store(_ doc: Documentation, to store: DocumentStore) async throws {
    // Get empty (mutable) stores to build on top of :)
    var index = EntryIndex()
    var pages = PageDatabase()

    // Process all pages
    for try await page in doc.buildPages() {
      try await store.write(page.path, content: page.content)
      index.add(page.entries)
      pages.add(path: page.path, content: page.content)
    }

    let encoder = JSONEncoder()

    // Create the wrapper for both
    let full = Meta(index: index, information: doc)

    let fullData = try encoder.encode(full)
    try await store.write(doc.metaPath, data: fullData)

    logger.info("Successfully stored doc: \(doc.slug)")
  }
}
