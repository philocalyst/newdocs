import SemVer

public protocol Package {
  var slug: String { get set }  // The true/unqualified name
  var lang: Languages { get set }  // The language it's related to
  var UUID: UInt64 { get }  // The identifier of the package
  var source: String { get }  // The associated parent/host; like the package manager it's hosted upon, or just the fact that it's the standard library reference. For a crates.io package, it might be "crates"

  // These are all async due to possible network requests/file IO
  func get_available_versions() async throws -> [Version]  // All of the published versions.
  func flags() async throws -> [String]?  // All of the available flags.
  func description() async throws -> String?  // A provided description as to the purpose of this package
  func dependencies() async throws -> [Package]  // Any other packages that this package relies on (none is an empty array)
  func dependents() async throws -> [Package]  // Any other packages that rely on this package (none is an empty array)

  // We should only require the slug for initialization. The name is purely cosmetic so not required
  init(slug: String, name: String?)

  func retrieve(at version: Version, flags: [String]?) async throws -> Doc  // With the information, get the most relevant, precise doc. It's up to the implementer to create default behavior if applicable for the version specifier. Not every language package has the concept of flags so it can just be passed in as nil. Can throw as this is a signficant resolution step. A lot could go wrong.
}
