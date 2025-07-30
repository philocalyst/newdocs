import Foundation

public protocol EntryIndexing {
  var isEmpty: Bool { get }
  var count: Int { get }

  mutating func add(_ entry: Entry)
  mutating func add(_ entries: [Entry])
  func asJSON() -> [String: Any]
  func toJSON() throws -> Data
}

public struct EntryIndex: EntryIndexing {
  private var entries: Set<Entry> = []

  public init() {}

  public var isEmpty: Bool {
    return entries.isEmpty
  }

  public var count: Int {
    return entries.count
  }

  public mutating func add(_ entry: Entry) {
    guard !entry.isRoot else { return }
    entries.insert(entry)
  }

  public mutating func add(_ entries: [Entry]) {
    for entry in entries {
      guard !entry.isRoot else { continue }
      self.entries.insert(entry)
    }
  }

  public func asJSON() -> [String: Any] {
    // Sort the entries by their names
    let sortedEntries = entries.sorted { a, b in
      sortNames(a.name, b.name)
    }

    // Build the types map, and enforce conversion to DocumentationType. Where each key (Name) corresponds to a DocumentationType
    let typesMap: [String: EntryType] = Dictionary(grouping: sortedEntries, by: \.type)
      .mapValues { group in
        EntryType(name: group[0].type, count: group.count)
      }

    // Convert to JSON and sort the types by names
    let sortedTypesJSON = typesMap.values
      .sorted { sortNames($0.name, $1.name) }
      .map { $0.asJSON() }

    return [
      "entries": sortedEntries.map { $0.asJSON() },
      "types": sortedTypesJSON,
    ]
  }

  public func toJSON() throws -> Data {
    return try JSONSerialization.data(
      withJSONObject: asJSON(),
      options: .prettyPrinted
    )
  }

  private func sortNames(_ a: String, _ b: String) -> Bool {
    let aFirstByte = a.first?.asciiValue ?? 0
    let bFirstByte = b.first?.asciiValue ?? 0

    let aIsDigit = (49...57).contains(aFirstByte)
    let bIsDigit = (49...57).contains(bFirstByte)

    if aIsDigit || bIsDigit {
      let aSplit = a.components(separatedBy: CharacterSet(charactersIn: ".-"))
      let bSplit = b.components(separatedBy: CharacterSet(charactersIn: ".-"))

      if aSplit.count == 1 && bSplit.count == 1 {
        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
      }
      if aSplit.count == 1 { return false }
      if bSplit.count == 1 { return true }

      return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    } else {
      return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    }
  }
}
