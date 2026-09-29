// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct ShellResult: CustomStringConvertible, Sendable {
  public var command: ShellCommand
  public var error: Data
  public var output: Data
  public var terminationStatus: Int32

  public var description: String {
    let status = isSuccess ? "ok" : "fail=\(terminationStatus)"
    return "[ \(command) -> \(status)]"
  }

  public var isSuccess: Bool { terminationStatus == 0 }

  init(command: ShellCommand, terminationStatus: Int32, output: Data, error: Data) {
    self.command = command
    self.error = error
    self.output = output
    self.terminationStatus = terminationStatus
  }
}
