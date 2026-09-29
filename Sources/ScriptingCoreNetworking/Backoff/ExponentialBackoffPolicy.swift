// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation

/// Equal Jitter from https://aws.amazon.com/ru/blogs/architecture/exponential-backoff-and-jitter
/// See also https://github.com/aws-samples/aws-arch-backoff-simulator/
public struct ExponentialBackoffPolicy: BackoffPolicy {
  public var base: Duration
  public var cap: Duration
  public var factor: Double

  public init(
    base: Duration,
    cap: Duration,
    factor: Double
  ) {
    self.base = base
    self.cap = cap
    self.factor = factor
  }

  public func nextTimeout(failedRequests: Int) -> Duration {
    let multiplier = failedRequests > 1 ? factor : pow(factor, Double(failedRequests))
    let topBound = min(cap, base * multiplier)
    return topBound / 2 + topBound * Double.random(in: 0...0.5)
  }
}
