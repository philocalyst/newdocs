// Sources/DocsKit/Core/Manifest.swift
import Foundation

public class Manifest {
  private let store: DocumentStore
  private let docs: [Doc]
  private static let filename = "docs.json"

  public init(store: DocumentStore, docs: [Doc]) {
    self.store = store
    self.docs = docs
  }

  public func store() async throws {
    let jsonData = try await toJSON()
    try await store.write(Self.filename, data: jsonData)
  }

  public func asJSON() async throws -> [[String: Any]] {
    var result: [[String: Any]] = []

    for doc in docs {
      guard await store.exists(doc.metaPath) else { continue }

      let metaContent = try await store.read(doc.metaPath)
      guard let metaData = metaContent.data(using: .utf8),
        var json = try JSONSerialization.jsonObject(with: metaData) as? [String: Any]
      else {
        continue
      }

      // Add any additional metadata processing here
      result.append(json)
    }

    return result
  }

  public func toJSON() async throws -> Data {
    let jsonObject = try await asJSON()
    return try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
  }
}
