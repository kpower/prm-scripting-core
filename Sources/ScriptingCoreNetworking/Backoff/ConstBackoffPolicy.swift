// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public struct ConstBackoffPolicy: BackoffPolicy {
  public var timeout: Duration

  public init(timeout: Duration) {
    self.timeout = timeout
  }

  public func nextTimeout(failedRequests: Int) -> Duration {
    timeout
  }
}
