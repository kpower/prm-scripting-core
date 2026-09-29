// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public enum HTTPRetryPolicyFactory {
  public static let defaultProcessUrlResponse: DefaultHTTPRetryPolicy.ProcessURLResponse = {
    switch $0.statusCode {
    case HTTPStatusCodeGroup.successful.statusCodes: .success
    case HTTPStatusCodeGroup.serverError.statusCodes: .retry
    default: .failure
    }
  }

  public static func makeDefaultHttpRetryPolicy(
    backoffType: BackoffPolicyFactory.PolicyType,
    latency: BackoffPolicyFactory.Latency,
    processUrlResponse: @escaping DefaultHTTPRetryPolicy.ProcessURLResponse = defaultProcessUrlResponse
  ) -> DefaultHTTPRetryPolicy {
    DefaultHTTPRetryPolicy(
      backoffPolicy: BackoffPolicyFactory.makeBackoff(type: backoffType, latency: latency),
      maxRetries: latency.maxRetries,
      processUrlResponse: processUrlResponse
    )
  }
}

// MARK: -

extension BackoffPolicyFactory.Latency {
  fileprivate var maxRetries: Int {
    switch self {
    case .long:   20
    case .medium: 15
    case .short:  10
    }
  }
}
