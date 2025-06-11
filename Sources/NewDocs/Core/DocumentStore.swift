// Sources/NewDocs/Storage/DocumentStore.swift
import Foundation

public protocol DocumentStore {
  func write(_ path: String, content: String) async throws
  func write(_ path: String, data: Data) async throws
  func read(_ path: String) async throws -> String
  func exists(_ path: String) async -> Bool
  func size(_ path: String) async throws -> Int
  func delete(_ path: String) async throws
  func list(_ directory: String) async throws -> [String]
}

public struct FileSystemStore: DocumentStore {
  private let baseDirectory: URL

  public init(baseDirectory: String) throws {
    self.baseDirectory = URL(fileURLWithPath: baseDirectory)
    try createDirectoryIfNeeded()
  }

  private func createDirectoryIfNeeded() throws {
    try FileManager.default.createDirectory(
      at: baseDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  public func write(_ path: String, content: String) async throws {
    try await write(path, data: content.data(using: .utf8) ?? Data())
  }

  public func write(_ path: String, data: Data) async throws {
    let fileURL = baseDirectory.appendingPathComponent(path)
    let directoryURL = fileURL.deletingLastPathComponent()

    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    try data.write(to: fileURL)
  }

  public func read(_ path: String) async throws -> String {
    let fileURL = baseDirectory.appendingPathComponent(path)
    let data = try Data(contentsOf: fileURL)
    guard let content = String(data: data, encoding: .utf8) else {
      throw DocsError.parsingError("Could not decode file as UTF-8: \(path)")
    }
    return content
  }

  public func exists(_ path: String) async -> Bool {
    let fileURL = baseDirectory.appendingPathComponent(path)
    return FileManager.default.fileExists(atPath: fileURL.path)
  }

  public func size(_ path: String) async throws -> Int {
    let fileURL = baseDirectory.appendingPathComponent(path)
    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
    return (attributes[.size] as? Int) ?? 0
  }

  public func delete(_ path: String) async throws {
    let fileURL = baseDirectory.appendingPathComponent(path)
    try FileManager.default.removeItem(at: fileURL)
  }

  public func list(_ directory: String) async throws -> [String] {
    let directoryURL = baseDirectory.appendingPathComponent(directory)
    return try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
  }
}
