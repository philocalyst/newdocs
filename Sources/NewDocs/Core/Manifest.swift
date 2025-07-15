import Foundation

public protocol ManifestProtocol {
  func generate(docs: [Doc], store: DocumentStore) async throws
}

public struct Manifest: ManifestProtocol {
  private static let filename = "docs.json"

  public init() {}

  public func generate(docs: [Doc], store: DocumentStore) async throws {
    let jsonData = try await toJSON(docs: docs, store: store)
    try await store.write(Self.filename, data: jsonData)
  }

  private func asJSON(docs: [Doc], store: DocumentStore) async throws -> [[String: Any]] {
    var result: [[String: Any]] = []

    for doc in docs {
      guard await store.exists(doc.metaPath) else { continue }

      let metaContent = try await store.read(doc.metaPath)
      guard let metaData = metaContent.data(using: .utf8),
        var json = try JSONSerialization.jsonObject(with: metaData) as? [String: Any]
      else {
        continue
      }

      result.append(json)
    }

    return result
  }

  private func toJSON(docs: [Doc], store: DocumentStore) async throws -> Data {
    let jsonObject = try await asJSON(docs: docs, store: store)
    return try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
  }
}
