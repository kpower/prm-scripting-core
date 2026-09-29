// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public enum PathExistence {
  case exist(isDirectory: Bool)
  case unavailable(Error)
}
