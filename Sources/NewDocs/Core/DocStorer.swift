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

    // Write index.json
    let indexData = try index.toJSON()
    try await store.write(doc.indexPath, data: indexData)

    // Write db.json
    let dbData = try pages.toJSON()
    try await store.write(doc.dbPath, data: dbData)

    // Write meta.json
    var meta = doc.asJSON()
    meta["mtime"] = Int(Date().timeIntervalSince1970)
    meta["db_size"] = try await store.size(doc.dbPath)
    let metaData = try JSONSerialization.data(withJSONObject: meta, options: .prettyPrinted)
    try await store.write(doc.metaPath, data: metaData)

    logger.info("Successfully stored doc: \(doc.slug)")
  }
}
