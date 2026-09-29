// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct ConsoleStringTransform: Sendable {
  var modifications: [@Sendable (String) -> String]

  public init(modifications: [@Sendable (String) -> String] = []) {
    self.modifications = modifications
  }

  public func modify(_ block: @escaping @Sendable (String) -> String) -> Self {
    Self(modifications: modifications + [ block ])
  }

  public func trim(_ charset: CharacterSet) -> Self {
    modify {
      $0.trimmingCharacters(in: charset)
    }
  }

  public func lowercase() -> Self {
    modify {
      $0.lowercased()
    }
  }

  public func process(string: String) -> String {
    modifications.reduce(string) {
      $1($0)
    }
  }
}
