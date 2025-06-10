// Sources/DocsKit/Models/Entry.swift
import Foundation

public struct Entry: Codable, Equatable, Hashable {
  public let name: String
  public let path: String
  public let type: String

  public init(name: String, path: String, type: String) throws {
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DocsError.invalidEntry("missing name")
    }
    guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DocsError.invalidEntry("missing path")
    }
    guard !type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DocsError.invalidEntry("missing type")
    }

    self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.path = path.trimmingCharacters(in: .whitespacesAndNewlines)
    self.type = type.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public var isRoot: Bool {
    return path == "index"
  }

  public func asJSON() -> [String: Any] {
    return [
      "name": name,
      "path": path,
      "type": type,
    ]
  }
}
