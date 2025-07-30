import Foundation

public struct DocumentationPage {
  public let path: String
  public let content: String
  public let internalURLs: [URL]
  public let entries: [Entry]

  public init(
    path: String,
    content: String,
    internalURLs: [URL],
    entries: [Entry],
  ) {
    self.path = path
    self.content = content
    self.entries = entries
    self.internalURLs = internalURLs
  }
}
