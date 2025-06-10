// Sources/DocsKit/Parsing/HTMLParser.swift
import Foundation
import Logging
import SwiftSoup

public class HTMLParser {
  public let title: String?
  public let document: Document

  public init(_ content: String) throws {
    if content.range(
      of: #"(?i)\A(?:\s|(?:<!--.*?-->))*<(?:\!doctype|html)"#, options: .regularExpression) != nil
    {
      // Parse as full document
      document = try SwiftSoup.parse(content)
      title = try document.select("title").first()?.text()
    } else {
      // Parse as fragment
      document = try SwiftSoup.parseBodyFragment(content)
      title = nil
    }
  }
}
