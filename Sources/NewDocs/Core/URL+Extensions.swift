import Foundation

public struct DocsURL: Equatable, Hashable {
  public let url: URL

  public init(_ string: String) throws {
    guard let url = URL(string: string) else {
      throw DocsError.invalidConfiguration("Invalid URL: \(string)")
    }
    self.url = url
  }

  public init(_ url: URL) {
    self.url = url
  }

  public var origin: String? {
    guard let scheme = url.scheme, let host = url.host else { return nil }
    var origin = "\(scheme)://\(host)"
    if let port = url.port {
      origin += ":\(port)"
    }
    return origin
  }

  public var normalizedPath: String {
    return url.path.isEmpty ? "/" : url.path
  }

  public func subpath(to other: DocsURL, ignoreCase: Bool = false) -> String? {
    guard origin == other.origin else { return nil }

    let basePath = ignoreCase ? url.path.lowercased() : url.path
    let destPath = ignoreCase ? other.url.path.lowercased() : other.url.path

    if basePath == destPath {
      return ""
    } else if destPath.hasPrefix(basePath + "/") {
      return String(other.url.path.dropFirst(url.path.count))
    }
    return nil
  }

  public func contains(_ other: DocsURL, ignoreCase: Bool = false) -> Bool {
    return subpath(to: other, ignoreCase: ignoreCase) != nil
  }

  public func joining(_ path: String) -> DocsURL {
    let newURL = url.appendingPathComponent(path)
    return DocsURL(newURL)
  }
}

extension DocsURL: CustomStringConvertible {
  public var description: String {
    return url.absoluteString
  }
}
