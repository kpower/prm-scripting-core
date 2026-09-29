// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public protocol BackoffPolicy: Sendable {
  /// get next retry timeout, based on failed requests count
  func nextTimeout(failedRequests: Int) -> Duration
}
