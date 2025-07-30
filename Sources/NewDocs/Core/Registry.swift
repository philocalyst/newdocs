public protocol PackageRegistry {
  func search_packages(for query: String) async -> Result<[Package], NewDocsError>  // Search all of the available packages for a specific language and return any hits, where no hits are represented as an emtpy array (async and possible failures due to network requests)
  func get_package(UUID: UInt64) async -> Result<Package, NewDocsError>  // Find a specific package by UUID (can fail because it's performing a lookup, async for the same reason) A failed lookup will throw an error.
  func get_package(named: String) async -> Result<[Package], NewDocsError>  // Find all packages that share a specific name
  func get_reference() async -> Package  // Return the package reflecting the language reference. Not falliable as it's just filling in known information largely.
}
