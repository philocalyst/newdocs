import SemVer

public struct NewDocs {
  public func registry(for language: Language) -> PackageRegistry {

  }

  public func buildPackage(
    package: Package,
    version: Version,
    features: [String] = [],
  ) async throws -> Doc {
    try await package.retrieve(at: version, flags: features)
  }
}
