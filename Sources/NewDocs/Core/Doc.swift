import Foundation
import Logging

public enum OutdatedState: String, CaseIterable {
  case upToDate = "Up-to-date"
  case outdatedMinor = "Outdated minor version"
  case outdatedMajor = "Outdated major version"
}

public protocol Doc: Instrumentable {
  var name: String { get }  // The name you'd expect to see it referred to as
  var slug: String { get }  // The battle-ready slug for encoding and references
  var type: String { get }
  var latest: String? { get }  // The latest version we're aware of in the "software"
  var links: [String: URL] { get }

  func buildPages() -> AsyncStream<PageResult>
  func getLatestVersion() async throws -> String
  func getScraperVersion() async throws -> String
  func outdatedState(scraperVersion: String, latestVersion: String) -> OutdatedState
}

extension Doc {
  /// Returns the typical pathing for an index
  public var indexPath: String {
    return "\(slug)/index.json"
  }

  /// Returns the typical pathing for a DB
  public var dbPath: String {
    return "\(slug)/db.json"
  }

  /// Returns the typical pathing for the meta files
  public var metaPath: String {
    return "\(slug)/meta.json"
  }

  /// Returns the Doc as a JSONL object
  public func asJSON() -> [String: Any] {
    var json: [String: Any] = [
      "name": name,
      "slug": slug,
      "type": type,
    ]

    if !links.isEmpty {
      json["links"] = links
    }

    if let release = latest {
      json["release"] = release
    }

    return json
  }

  /// Returns the version of the scraper. If none is found, a 1.0.0
  public func getScraperVersion() async throws -> String {
    return latest ?? "1.0.0"
  }

  /// Determine whether or not the doc has outdated contents
  public func outdatedState(scraperVersion: String, latestVersion: String) -> OutdatedState {
    // Break the input string into major/minor/patch components
    let scraperParts = scraperVersion.components(separatedBy: CharacterSet(charactersIn: ".-"))
      .compactMap { Int($0) }

    // Break the input string into major/minor/patch components
    let latestParts = latestVersion.components(separatedBy: CharacterSet(charactersIn: ".-"))
      .compactMap { Int($0) }

    // Iterate through and determine equality
    for i in 0..<min(2, min(scraperParts.count, latestParts.count)) {
      if i == 0 && latestParts[i] > scraperParts[i] {
        return .outdatedMajor
      }
      if i == 1 && latestParts[i] > scraperParts[i] {
        if (latestParts[0] == 0 && scraperParts[0] == 0)
          || (latestParts[0] == 1 && scraperParts[0] == 1)
        {
          return .outdatedMajor
        }
        return .outdatedMinor
      }
      if latestParts[i] < scraperParts[i] {
        return .upToDate
      }
    }

    return .upToDate
  }

  // Utility methods for network requests
  public func fetchJSON(from urlString: String) async throws -> [String: Any] {
    let request = HTTPRequest(logger: logger)
    let response = try await request.request(urlString)
    guard response.isSuccess else {
      throw DocsError.networkError("Failed to fetch \(urlString): \(response.statusCode)")
    }
    return try response.asJSON()
  }

  public func getNPMVersion(package: String, tag: String = "latest") async throws -> String {
    let json = try await fetchJSON(from: "https://registry.npmjs.com/\(package)")
    guard let distTags = json["dist-tags"] as? [String: Any],
      let version = distTags[tag] as? String
    else {
      throw DocsError.parsingError("Could not parse npm version for \(package)")
    }
    return version
  }

  public func getLatestGitHubRelease(owner: String, repo: String) async throws -> String {
    let json = try await fetchJSON(
      // Getting the release endpoint
      from: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")
    guard let tagName = json["tag_name"] as? String else {
      throw DocsError.parsingError("Could not parse GitHub release tag")
    }
    return tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
  }
}
