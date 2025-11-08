import Foundation

public struct DocumentationPage {
  public let path: [String]  // Array of components
  public let internalURLs: [URL]
  public let entries: [Entry]

  public init(
    path: [String],
    internalURLs: [URL],
    entries: [Entry],
  ) {
    self.path = path
    self.entries = entries
    self.internalURLs = internalURLs
  }
}
