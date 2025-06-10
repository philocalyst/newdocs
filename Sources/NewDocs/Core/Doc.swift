// Sources/DocsKit/Core/Doc.swift
import Foundation
import Logging

public protocol DocProtocol: AnyObject, Instrumentable {
    var name: String { get }
    var slug: String { get }
    var type: String { get }
    var version: String? { get }
    var release: String? { get }
    var isAbstract: Bool { get }
    var links: [String: String] { get }
    
    func buildPage(id: String) async throws -> PageResult?
    func buildPages() async throws -> AsyncStream<PageResult>
    func getLatestVersion() async throws -> String
    func getScraperVersion() async throws -> String
    func outdatedState(scraperVersion: String, latestVersion: String) -> OutdatedState
}

public enum OutdatedState: String, CaseIterable {
    case upToDate = "Up-to-date"
    case outdatedMinor = "Outdated minor version"
    case outdatedMajor = "Outdated major version"
}

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

open class Doc: DocProtocol {
    public let logger: Logger
    public let name: String
    public let slug: String
    public let type: String
    public let version: String?
    public let release: String?
    public let isAbstract: Bool
    public let links: [String: String]
    
    private static let indexFilename = "index.json"
    private static let dbFilename = "db.json"
    private static let metaFilename = "meta.json"
    
    public init(
        name: String,
        slug: String,
        type: String,
        version: String? = nil,
        release: String? = nil,
        isAbstract: Bool = false,
        links: [String: String] = [:],
        logger: Logger = Logger(label: "Doc")
    ) throws {
        guard !isAbstract else {
            throw DocsError.setupError("\(name) is an abstract class and cannot be instantiated")
        }
        
        self.name = name
        self.slug = version != nil ? "\(slug)~\(version!)" : slug
        self.type = type
        self.version = version
        self.release = release
        self.isAbstract = isAbstract
        self.links = links
        self.logger = logger
    }
    
    public var path: String {
        return slug
    }
    
    public var indexPath: String {
        return "\(path)/\(Self.indexFilename)"
    }
    
    public var dbPath: String {
        return "\(path)/\(Self.dbFilename)"
    }
    
    public var metaPath: String {
        return "\(path)/\(Self.metaFilename)"
    }
    
    public func asJSON() -> [String: Any] {
        var json: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type
        ]
        
        if !links.isEmpty {
            json["links"] = links
        }
        
        if let version = version {
            json["version"] = version
        }
        
        if let release = release {
            json["release"] = release
        }
        
        return json
    }
    
    // Abstract methods to be overridden
    open func buildPage(id: String) async throws -> PageResult? {
        throw DocsError.setupError("buildPage must be implemented by subclass")
    }
    
    open func buildPages() async throws -> AsyncStream<PageResult> {
        throw DocsError.setupError("buildPages must be implemented by subclass")
    }
    
    open func getLatestVersion() async throws -> String {
        throw DocsError.setupError("getLatestVersion must be implemented by subclass")
    }
    
    open func getScraperVersion() async throws -> String {
        return release ?? "1.0.0"
    }
    
    open func outdatedState(scraperVersion: String, latestVersion: String) -> OutdatedState {
        let scraperParts = scraperVersion.components(separatedBy: CharacterSet(charactersIn: ".-"))
            .compactMap { Int($0) }
        let latestParts = latestVersion.components(separatedBy: CharacterSet(charactersIn: ".-"))
            .compactMap { Int($0) }
        
        for i in 0..<min(2, min(scraperParts.count, latestParts.count)) {
            if i == 0 && latestParts[i] > scraperParts[i] {
                return .outdatedMajor
            }
            if i == 1 && latestParts[i] > scraperParts[i] {
                if (latestParts[0] == 0 && scraperParts[0] == 0) ||
                   (latestParts[0] == 1 && scraperParts[0] == 1) {
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
    internal func fetchJSON(from urlString: String) async throws -> [String: Any] {
        let request = HTTPRequest(logger: logger)
        let response = try await request.request(urlString)
        guard response.isSuccess else {
            throw DocsError.networkError("Failed to fetch \(urlString): \(response.statusCode)")
        }
        return try response.asJSON()
    }
    
    internal func getNPMVersion(package: String, tag: String = "latest") async throws -> String {
        let json = try await fetchJSON(from: "https://registry.npmjs.com/\(package)")
        guard let distTags = json["dist-tags"] as? [String: Any],
              let version = distTags[tag] as? String else {
            throw DocsError.parsingError("Could not parse npm version for \(package)")
        }
        return version
    }
    
    internal func getLatestGitHubRelease(owner: String, repo: String) async throws -> String {
        let json = try await fetchJSON(from: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")
        guard let tagName = json["tag_name"] as? String else {
            throw DocsError.parsingError("Could not parse GitHub release tag")
        }
        return tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}
