// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

extension JSONNumber {
  public func requireDouble() -> Double {
    switch storage {
    case let .int(value):   Double(value)
    case let .float(value): Double(value)
    }
  }

  public func requireInt() throws -> Int {
    switch storage {
    case let .int(value): Int(value)
    case .float:          throw DescribedError("Integer expected, got \(self)")
    }
  }
}
