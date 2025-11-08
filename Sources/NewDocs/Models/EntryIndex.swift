import Foundation

public protocol EntryIndexing {
  var isEmpty: Bool { get }
  var count: Int { get }

  mutating func add(_ entry: Entry)
  mutating func add(_ entries: [Entry])
}

public struct EntryIndex: EntryIndexing, Encodable {
  private var entries: Set<Entry> = []

  public init() {}

  public var isEmpty: Bool {
    return entries.isEmpty
  }

  public var count: Int {
    return entries.count
  }

  public mutating func add(_ entry: Entry) {
    entries.insert(entry)
  }

  public mutating func add(_ entries: [Entry]) {
    for entry in entries {
      self.entries.insert(entry)
    }
  }

  enum CodingKeys: String, CodingKey {
    case entries
    case types
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    // Sort the entries by their names
    let sortedEntries = entries.sorted { a, b in
      sortNames(a.name, b.name)
    }

    // Convert to JSON and sort the types by names
    let sortedTypesJSON =
      sortedEntries
      .sorted { sortNames($0.name, $1.name) }

    try container.encode(sortedEntries, forKey: CodingKeys.entries)
    try container.encode(sortedTypesJSON, forKey: CodingKeys.types)

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
