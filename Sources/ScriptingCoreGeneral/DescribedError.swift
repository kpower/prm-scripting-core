// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public struct DescribedError: Error, CustomStringConvertible {
  public var description: String

  public init(_ description: String) {
    self.description = description
  }
}
