// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
public import Logging

public struct Shell: Sendable {
  var logger: Logger
  var tool: ShellTool  

  public init(logger: Logger, tool: ShellTool = .autodetected) {
    self.logger = logger
    self.tool = tool
  }

  @discardableResult
  public func perform(command: ShellCommand) throws -> ShellResult {
    logger.debug("Execute shell command", metadata: [
      "command": .string(command.toolCommand),
    ])

    let result = try Process.runBash(
      tool: tool,
      command: command,
      onOutputChunk: {
        logger.trace("output chunk", metadata: [
          "data": .string($0.utf8String),
        ])
      },
      onErrorChunk: {
        logger.trace("error chunk", metadata: [
          "data": .string($0.utf8String),
        ])
      },
    )

    logger.log(level: result.isSuccess ? .debug : .error, "Shell command finished", metadata: [
      "result": .stringConvertible(result),
      "stdout": .string(result.output.utf8String),
      "stderr": .string(result.error.utf8String),
    ])
    guard result.isSuccess || !command.throwOnFailure else {
      throw ShellError.failed(result)
    }
    return result
  }
}

// MARK: - ShellError

private enum ShellError: Error {
  case failed(ShellResult)
}

// MARK: -

extension Data {
  fileprivate var utf8String: String {
    String(decoding: self, as: UTF8.self)
  }
}
