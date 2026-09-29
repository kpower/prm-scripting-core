// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public enum OAuthTokenType: Sendable {
  case general
  case team

  public func authHeaderValue(token: String) -> String {
    authHeaderValuePrefix + " " + token
  }

  private var authHeaderValuePrefix: String {
    switch self {
    case .general: "OAuth"
    case .team: "OAuthTeam"
    }
  }
}
