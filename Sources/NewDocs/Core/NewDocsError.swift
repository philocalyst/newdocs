import Foundation

public enum NewDocsError: Error, CustomStringConvertible {
  case setupError(String)
  case invalidEntry(String)
  case networkError(String)
  case parsingError(String)
  case fileNotFound(String)
  case invalidConfiguration(String)

  public var description: String {
    switch self {
    case .setupError(let message): return "Setup Error: \(message)"
    case .invalidEntry(let message): return "Invalid Entry: \(message)"
    case .networkError(let message): return "Network Error: \(message)"
    case .parsingError(let message): return "Parsing Error: \(message)"
    case .fileNotFound(let message): return "File Not Found: \(message)"
    case .invalidConfiguration(let message): return "Invalid Configuration: \(message)"
    }
  }
}
