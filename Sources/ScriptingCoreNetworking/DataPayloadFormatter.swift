// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation

public enum DataPayloadFormatter: Sendable {
  /// print data count
  case count
  /// print data as string
  case string

  func string(payload: Data) -> String {
    switch self {
    case .count:
      "<data count:\(payload.count) />"
    case .string:
      String(data: payload, encoding: .utf8) ?? Self.count.string(payload: payload)
    }
  }
}
