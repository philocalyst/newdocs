import SemVer

public struct NewDocumentations {
  public func registry(for language: Language) -> PackageRegistry {
    switch language {
    case .Rust:
      return CargoRegistry()
    default:
      fatalError("Language \(language) not yet supported")
    }
  }

  public func buildPackage(
    package: Package,
    version: Version,
    features: [String] = [],
  ) async throws -> Documentation {
    try await package.retrieve(at: version, flags: features)
  }
}
