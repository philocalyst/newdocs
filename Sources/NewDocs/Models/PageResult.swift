import Foundation

public struct DocumentationPage {
  public let path: String
  public let content: String
  public let entries: [Entry]

  public init(
    path: String,
    output: String,
    entries: [Entry],
  ) {
    self.path = path
    self.content = output
    self.entries = entries
  }
}
