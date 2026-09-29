// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct ShellCommand: CustomStringConvertible, Sendable {
  public var arguments: [String]
  public var currentDirectoryURL: URL?
  public var throwOnFailure: Bool
  public var tool: ShellTool

  public var description: String {
    tool.executableURL.path() + " " + arguments.joined(separator: " ")
      + (currentDirectoryURL.map { "-- '\($0.path())'" } ?? "")
  }

  /// Makes a command that runs `command` in interactive sh mode (see `bash -c` help).
  ///
  /// - Parameters:
  ///   - command: shell script text passed to `-c`.
  ///   - positionalParameters: extra arguments, assigned to the positional parameters of command, starting with `$0`.
  ///   - currentDirectoryURL: working directory for the process, `nil` inherits the current one.
  ///   - throwOnFailure: whether `run` throws when the command exits with a non-zero status.
  public static func makeAutoShInteractive(
    _ command: String,
    positionalParameters: [String] = [],
    currentDirectoryURL: URL? = nil,
    throwOnFailure: Bool = true,
  ) -> Self {
    ShellCommand(
      tool: .autoSh,
      arguments: [ "-c", command ] + positionalParameters,
      currentDirectoryURL: currentDirectoryURL,
      throwOnFailure: throwOnFailure
    )
  }

  public init(
    tool: ShellTool = .autoSh,
    arguments: [String] = [],
    currentDirectoryURL: URL? = nil,
    throwOnFailure: Bool = true,
  ) {
    self.arguments = arguments
    self.currentDirectoryURL = currentDirectoryURL
    self.throwOnFailure = throwOnFailure
    self.tool = tool
  }
}
