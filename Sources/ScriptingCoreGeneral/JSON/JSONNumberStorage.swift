// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

enum JSONNumberStorage: Equatable, Sendable {
  case int(any BinaryInteger & Sendable & Encodable)
  case float(any BinaryFloatingPoint & Sendable & Encodable)

  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.int(lhsValue), .int(rhsValue)):
      if let lhsConverted = Int128(exactly: lhsValue), let rhsConverted = Int128(exactly: rhsValue) {
        lhsConverted == rhsConverted
      } else {
        false
      }
    case let (.float(lhsValue), .float(rhsValue)):
      if let lhsConverted = Double(exactly: lhsValue), let rhsConverted = Double(exactly: rhsValue) {
        lhsConverted == rhsConverted
      } else {
        false
      }
    case let (.int(lhsValue), .float(rhsValue)):
      if let lhsConverted = Double(exactly: lhsValue), let rhsConverted = Double(exactly: rhsValue) {
        lhsConverted == rhsConverted
      } else {
        false
      }
    case let (.float(lhsValue), .int(rhsValue)):
      if let lhsConverted = Double(exactly: lhsValue), let rhsConverted = Double(exactly: rhsValue) {
        lhsConverted == rhsConverted
      } else {
        false
      }
    }
  }
}
