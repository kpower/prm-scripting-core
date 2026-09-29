// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public enum PartiallyKnown<Known: RawRepresentable>: RawRepresentable {
  case known(Known)
  case unknown(Known.RawValue)

  public var rawValue: Known.RawValue {
    switch self {
    case let .known(known): known.rawValue
    case let .unknown(rawValue): rawValue
    }
  }

  public init(rawValue: Known.RawValue) {
    if let known = Known(rawValue: rawValue) {
      self = .known(known)
    } else {
      self = .unknown(rawValue)
    }
  }
}

extension PartiallyKnown: CustomStringConvertible
where Known: CustomStringConvertible, Known.RawValue: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .known(known): known.description
    case let .unknown(rawValue): rawValue.description
    }
  }
}

extension PartiallyKnown: Equatable
where Known: Equatable, Known.RawValue: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

extension PartiallyKnown: Comparable
where Known: Comparable, Known.RawValue: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension PartiallyKnown: Sendable
where Known: Sendable, Known.RawValue: Sendable {
}
