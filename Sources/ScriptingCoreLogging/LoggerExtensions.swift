// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Logging

extension Logger {
  public static func prm_makeLogger(label: String, logLevel: Logger.Level? = nil) -> Self {
    var logger = Self(label: label)
    if let logLevel {
      logger.logLevel = logLevel
    }
    return logger
  }

  public static func prm_makeLogger<T>(of type: T.Type, logLevel: Logger.Level? = nil) -> Self {
    prm_makeLogger(label: String(describing: type), logLevel: logLevel)
  }

  public func prm_makeChildLogger(suffix: String, glue: String = ".") -> Self {
    var logger = Self(label: label + glue + suffix)
    logger.logLevel = logLevel
    return logger
  }

  public func prm_makeChildLogger<T>(of type: T.Type, glue: String = ".") -> Self {
    prm_makeChildLogger(suffix: String(describing: type), glue: glue)
  }
}
