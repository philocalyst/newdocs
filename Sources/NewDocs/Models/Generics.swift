import Foundation

/// A universal representation of generics across languages.
public struct Generics: Codable, Sendable {
  public var typeParams: [TypeParam]
  public var constParams: [ConstParam]
  public var lifetimeParams: [LifetimeParam]
  public var constraints: [Constraint]
}

// MARK: - Type Parameters

public struct TypeParam: Codable, Sendable {
  public var name: String
  public var kind: TypeKind
  public var variance: Variance
  public var defaultType: TypeExpr?
}

public enum TypeKind: String, Codable, Sendable {
  case type
  case higherKinded
  case associated
}

// MARK: - Const Parameters

public struct ConstParam: Codable, Sendable {
  public var name: String
  public var type: TypeExpr
  public var defaultValue: ConstExpr?
}

// MARK: - Lifetime Parameters (Rust-style)

public struct LifetimeParam: Codable, Sendable {
  public var name: String
  public var variance: Variance
}

// MARK: - Constraints

public enum Constraint: Codable, Sendable {
  case traitBound(param: String, trait: TraitRef)
  case associatedTypeBound(param: String, assocName: String, bound: TypeExpr)
  case higherKindedBound(param: String, kind: KindExpr)
  case lifetimeBound(shorter: String, longer: String)
  case constExprBound(param: String, expr: ConstExpr)
  case logicalPredicate(expr: PredicateExpr)
}

// MARK: - Supporting Types

public struct TraitRef: Codable, Sendable {
  public var name: String
  public var args: [TypeExpr]
}

public enum Variance: String, Codable, Sendable {
  case covariant
  case contravariant
  case invariant
  case bivariant
}

public struct TypeExpr: Codable, Sendable {
  public var name: String
  public var args: [TypeExpr]
}

public struct ConstExpr: Codable, Sendable {
  public var expr: String
}

public struct KindExpr: Codable, Sendable {
  public var signature: String  // e.g. "* -> *"
}

public struct PredicateExpr: Codable, Sendable {
  public var expr: String  // logical expression, e.g. "T: Clone && U: Copy"
}
