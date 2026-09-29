// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public struct ConsoleOutParams: Sendable {
  public static let inline = Self(terminator: "")

  public var terminator: String
  public var trim: Bool
  public var skipEmpty: Bool

  public init(skipEmpty: Bool = true, terminator: String = "\n", trim: Bool = false) {
    self.skipEmpty = skipEmpty
    self.terminator = terminator
    self.trim = trim
  }
}
