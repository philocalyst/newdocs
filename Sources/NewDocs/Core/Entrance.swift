import SemVer

public struct NewDocumentations {
  public func registry(for language: Language) -> PackageRegistry {

  }

  public func buildPackage(
    package: Package,
    version: Version,
    features: [String] = [],
  ) async throws -> Documentation {
    try await package.retrieve(at: version, flags: features)
  }
}
