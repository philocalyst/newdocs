// Sources/DocsKit/Core/EntryIndex.swift
import Foundation

public class EntryIndex {
  private var entries: [Entry] = []
  private var entrySet: Set<String> = []
  private var types: [String: DocType] = [:]

  public init() {}

  public func add(_ entry: Entry) {
    guard !entry.isRoot else { return }
    add([entry])
  }

  public func add(_ entries: [Entry]) {
    for entry in entries {
      guard !entry.isRoot else { continue }
      addEntry(entry)
    }
  }

  private func addEntry(_ entry: Entry) {
    let entryJSON = try! JSONSerialization.data(withJSONObject: entry.asJSON())
    let entryString = String(data: entryJSON, encoding: .utf8)!

    if entrySet.insert(entryString).inserted {
      entries.append(entry)
      if var type = types[entry.type] {
        type.count += 1
        types[entry.type] = type
      } else {
        types[entry.type] = DocType(name: entry.type, count: 1)
      }
    }
  }

  public var isEmpty: Bool {
    return entries.isEmpty
  }

  public var count: Int {
    return entries.count
  }

  public func asJSON() -> [String: Any] {
    let sortedEntries = entries.sorted { a, b in
      return sortFunction(a.name, b.name)
    }

    let sortedTypes = Array(types.values).sorted { a, b in
      return sortFunction(a.name, b.name)
    }

    return [
      "entries": sortedEntries.map { $0.asJSON() },
      "types": sortedTypes.map { $0.asJSON() },
    ]
  }

  public func toJSON() throws -> Data {
    return try JSONSerialization.data(withJSONObject: asJSON(), options: [])
  }

  private func sortFunction(_ a: String, _ b: String) -> Bool {
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

      // Version comparison logic would go here
      return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    } else {
      return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    }
  }
}
