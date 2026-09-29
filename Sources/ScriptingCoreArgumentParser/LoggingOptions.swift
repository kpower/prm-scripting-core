// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import ArgumentParser
public import Logging
import ScriptingCoreGeneral

public struct LoggingOptions: ParsableArguments {
  @Option(name: .customLong("log-level"), help: "Logging level", transform: Logger.Level.make(rawValue:))
  public var logLevel = Logger.Level.info

  public init() {}
}

extension Logger.Level {
  fileprivate static func make(rawValue: RawValue) throws -> Self {
    guard let result = Self(rawValue: rawValue) else {
      throw DescribedError("Unknown log level: \(rawValue)")
    }
    return result
  }
}
