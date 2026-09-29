// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public enum BackoffPolicyFactory {
  public static func makeBackoff(type: PolicyType, latency: Latency)-> BackoffPolicy {
    switch type {
    case .const:        ConstBackoffPolicy(latency: latency)
    case .linear:       LinearBackoffPolicy(latency: latency)
    case .exponential:  ExponentialBackoffPolicy(latency: latency)
    }
  }
}

extension BackoffPolicyFactory {
  public enum PolicyType {
    case const
    case linear
    case exponential
  }
}

extension BackoffPolicyFactory {
  public enum Latency {
    case long
    case medium
    case short
  }
}

// MARK: -

extension BackoffPolicyFactory.Latency {
  fileprivate var cap: Duration {
    switch self {
    case .long:   .seconds(300)
    case .medium: .seconds(120)
    case .short:  .seconds(30)
    }
  }
}

extension ConstBackoffPolicy {
  fileprivate init(latency: BackoffPolicyFactory.Latency) {
    timeout = switch latency {
    case .long:   .seconds(10)
    case .medium: .seconds(5)
    case .short:  .seconds(3)
    }
  }
}

extension ExponentialBackoffPolicy {
  fileprivate init(latency: BackoffPolicyFactory.Latency) {
    factor = 1.5
    cap = latency.cap

    base = switch latency {
    case .long:   .seconds(10)
    case .medium: .seconds(3)
    case .short:  .seconds(1)
    }
  }
}

extension LinearBackoffPolicy {
  fileprivate init(latency: BackoffPolicyFactory.Latency) {
    cap = latency.cap

    timeout = switch latency {
    case .long:   .seconds(10)
    case .medium: .seconds(5)
    case .short:  .seconds(1)
    }
  }
}
