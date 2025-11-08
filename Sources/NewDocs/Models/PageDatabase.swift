import Foundation

public protocol PageDatabaseProtocol: Codable {
  var isEmpty: Bool { get }

  mutating func add(path: String, content: String)
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
}
