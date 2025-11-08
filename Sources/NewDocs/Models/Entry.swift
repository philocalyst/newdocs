import Foundation

/// Strongly typed parameter
public struct Parameter: Codable, Sendable {
  public let name: String
  public let type: Type?
  public let attributes: [ParameterAttribute]?
  public let defaultValue: ConstExpr?
  public let description: String?
}

public enum ParameterAttribute: Codable, Sendable {
  case mutable
  case optional
}

public struct Entry: Codable {
  // Required
  public let name: String  // Semantic name for the entry (std::time, or to_string)
  public let path: [String]  // The absolute path leading to the first instance of this entry
  public let kind: Kind  // The kind of entry this is
  public let visibility: String?  // The visibility of this entry (public, private, flags?)

  public let documentation: String?  // The associated documentation

  public init(
    path: [String],
    kind: Kind,
    visibility: String? = nil,
    members: [String]? = nil,
    inputParameters: [Parameter]? = nil,
    outputParameters: [Parameter]? = nil,
    typeParameters: [String]? = nil,
    documentation: String? = nil,
    name: String,
  ) throws {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      throw NewDocsError.invalidEntry("missing name")
    }

    self.path = path
    self.kind = kind
    self.visibility = visibility
    self.documentation = documentation
    self.name = trimmedName
  }
}
