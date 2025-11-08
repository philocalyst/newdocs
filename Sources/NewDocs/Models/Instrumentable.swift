// Implements a tracing-like API for measuring and analyzing asynchronus operations.
// This activates and ends automagically !

import Foundation
import Logging

public protocol Instrumentable {
  var logger: Logger { get }
}

extension Instrumentable {
  public func instrument<T>(
    _ operationName: String,
    metadata: [String: Any]? = nil,
    operation: () async throws -> T
  ) async rethrows -> T {
    let start = Date()
    logger.info("Starting \(operationName)", metadata: Logger.Metadata(metadata ?? [:]))

    do {
      let result = try await operation()
      let duration = Date().timeIntervalSince(start)
      logger.info("Completed \(operationName) in \(duration)s")
      return result
    } catch {
      let duration = Date().timeIntervalSince(start)
      logger.error("Failed \(operationName) after \(duration)s: \(error)")
      throw error
    }
  }
}

extension Logger.Metadata {
  init(_ dictionary: [String: Any]) {
    self.init()
    for (key, value) in dictionary {
      self[key] = Logger.MetadataValue(stringLiteral: String(describing: value))
    }
  }
}
