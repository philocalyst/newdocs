// Sources/NewDocs/Models/PageResult.swift
import Foundation

public struct PageResult {
  public let path: String
  public let storePath: String
  public let output: String
  public let entries: [Entry]
  public let internalURLs: [String]

  public init(
    path: String,
    storePath: String,
    output: String,
    entries: [Entry],
    internalURLs: [String] = []
  ) {
    self.path = path
    self.storePath = storePath
    self.output = output
    self.entries = entries
    self.internalURLs = internalURLs
  }
}
