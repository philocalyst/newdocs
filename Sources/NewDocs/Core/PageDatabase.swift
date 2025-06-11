// Sources/NewDocs/Core/PageDatabase.swift
import Foundation

public protocol PageDatabaseProtocol {
  var isEmpty: Bool { get }

  mutating func add(path: String, content: String)
  func asJSON() -> [String: Any]
  func toJSON() throws -> Data
}

public struct PageDatabase: PageDatabaseProtocol {
  private var pages: [String: String] = [:]

  public init() {}

  public var isEmpty: Bool {
    return pages.isEmpty
  }

  public mutating func add(path: String, content: String) {
    pages[path] = content
  }

  public func asJSON() -> [String: Any] {
    return pages
  }

  public func toJSON() throws -> Data {
    return try JSONSerialization.data(withJSONObject: asJSON(), options: [])
  }
}
