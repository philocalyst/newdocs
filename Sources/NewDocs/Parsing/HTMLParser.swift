// Sources/NewDocs/Parsing/HTMLParser.swift
import Foundation
import Logging
import SwiftSoup

public protocol HTMLParsing {
  var title: String? { get }
  var document: Document { get }
}

public struct HTMLParser: HTMLParsing {
  public let title: String?
  public let document: Document

  public init(_ content: String) throws {
    if content.range(
      of: #"(?i)\A(?:\s|(?:<!--.*?-->))*<(?:\!doctype|html)"#, options: .regularExpression) != nil
    {
      document = try SwiftSoup.parse(content)
      title = try document.select("title").first()?.text()
    } else {
      document = try SwiftSoup.parseBodyFragment(content)
      title = nil
    }
  }
}
