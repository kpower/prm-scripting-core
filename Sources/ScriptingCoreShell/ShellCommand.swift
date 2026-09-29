// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct ShellCommand: CustomStringConvertible, Sendable {
  public var dir: URL?
  public var throwOnFailure: Bool
  public var toolCommand: String

  public var description: String {
    toolCommand
      + (dir.map { "-- '\($0.path)'" } ?? "")
  }

  public init(
    _ toolCommand: String,
    dir: URL? = nil,
    throwOnFailure: Bool = true
  ) {
    self.dir = dir
    self.throwOnFailure = throwOnFailure
    self.toolCommand = toolCommand
  }
}
