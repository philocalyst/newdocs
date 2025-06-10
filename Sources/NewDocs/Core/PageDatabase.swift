// Sources/DocsKit/Core/PageDatabase.swift
import Foundation

public class PageDatabase {
  private var pages: [String: String] = [:]

  public init() {}

  public func add(path: String, content: String) {
    pages[path] = content
  }

  public var isEmpty: Bool {
    return pages.isEmpty
  }

  public func asJSON() -> [String: Any] {
    return pages
  }

  public func toJSON() throws -> Data {
    return try JSONSerialization.data(withJSONObject: asJSON(), options: [])
  }
}
