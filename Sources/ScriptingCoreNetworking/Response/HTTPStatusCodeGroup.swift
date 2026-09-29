// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public enum HTTPStatusCodeGroup: CaseIterable, CustomStringConvertible {
  case informational
  case successful
  case redirection
  case clientError
  case serverError

  public var description: String {
    "\(statusCodes.lowerBound)..<\(statusCodes.upperBound)"
  }

  public var statusCodes: Range<Int> {
    switch self {
    case .informational: 100..<200
    case .successful: 200..<300
    case .redirection: 300..<400
    case .clientError: 400..<500
    case .serverError: 500..<600
    }
  }
}
