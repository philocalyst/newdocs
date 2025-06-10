// Sources/DocsKit/Models/DocType.swift
import Foundation

public struct DocType: Codable, Equatable, Hashable {
  public let name: String
  public var count: Int

  public init(name: String, count: Int = 0) {
    self.name = name
    self.count = count
  }

  public var slug: String {
    return name.lowercased()
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
  }

  public func asJSON() -> [String: Any] {
    return [
      "name": name,
      "count": count,
      "slug": slug,
    ]
  }
}
