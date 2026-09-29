// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public struct LinearBackoffPolicy: BackoffPolicy {
  public var cap: Duration
  public var timeout: Duration

  public init(timeout: Duration, cap: Duration) {
    self.cap = cap
    self.timeout = timeout
  }

  public func nextTimeout(failedRequests: Int) -> Duration {
    let timeout = failedRequests > 1
      ? timeout * Double(failedRequests)
      : timeout
    return min(timeout, cap)
  }
}
