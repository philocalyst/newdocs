import Foundation

public struct Entry: Codable, Equatable, Hashable {
  public let name: String  // Semnatic name for the doc (std::time)
  public let path: String  // The location of the doc (rust/std/time)
  public let type: String  // The kind of documentation (module, class, etc.)

  public init(name: String, path: String, type: String) throws {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      throw DocsError.invalidEntry("missing name")
    }
    guard !trimmedPath.isEmpty else {
      throw DocsError.invalidEntry("missing path")
    }
    guard !trimmedType.isEmpty else {
      throw DocsError.invalidEntry("missing type")
    }

    self.name = trimmedName
    self.path = trimmedPath
    self.type = trimmedType
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
