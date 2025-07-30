// Represents one kind of documentation entry, whether that be a class, method, etc.
// Sort of generalizable, which is why the name is encoded as a string. (But I'm thinking of changing this)
// Count is just the number of times we've seen this doctype relative to a particular doc
import Foundation

public struct EntryType: Codable, Equatable, Hashable {
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
