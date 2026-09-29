// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

extension RequestEndpoint {
  public enum Scheme: String, CustomStringConvertible, Sendable {
    case http
    case https

    public var description: String { rawValue }
  }
}
