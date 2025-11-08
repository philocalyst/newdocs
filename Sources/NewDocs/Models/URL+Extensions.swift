import Foundation

extension URL {
  /// Returns the path from `self` to `other` by removing the common
  /// leading components. Returns nil if there is no common prefix.
  func subpath(to other: URL, ignoreCase: Bool = false) -> String? {
    let baseComps = self.standardized.pathComponents
    let targetComps = other.standardized.pathComponents
    var idx = 0

    // Find how many leading components match
    while idx < baseComps.count && idx < targetComps.count {
      let a = baseComps[idx]
      let b = targetComps[idx]
      let same =
        ignoreCase
        ? (a.caseInsensitiveCompare(b) == .orderedSame)
        : (a == b)
      if !same { break }
      idx += 1
    }

    // If nothing matched, return nil (or “” if you prefer)
    guard idx > 0 else { return nil }

    // Slice off the common prefix and re-join
    let subComps = targetComps[idx...]
    return subComps.joined(separator: "/")
  }
}
