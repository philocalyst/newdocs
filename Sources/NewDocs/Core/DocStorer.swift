// Sources/NewDocs/Core/DocStorer.swift
import Foundation
import Logging

public protocol DocStorer {
  func store(_ doc: Doc, to store: DocumentStore) async throws
}

public struct DefaultDocStorer: DocStorer {
  private let logger: Logger

  public init(logger: Logger = Logger(label: "DocStorer")) {
    self.logger = logger
  }

  public func store(_ doc: Doc, to store: DocumentStore) async throws {
    var index = EntryIndex()
    var pages = PageDatabase()

    // Process all pages
    for await page in doc.buildPages() {
      try await store.write(page.storePath, content: page.output)
      index.add(page.entries)
      pages.add(path: page.path, content: page.output)
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
