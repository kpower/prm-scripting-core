// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

#if canImport(FoundationNetworking)
import Foundation
public import FoundationNetworking
#else
public import Foundation
#endif

// MARK: - DefaultHTTPRetryPolicy

public struct DefaultHTTPRetryPolicy: HTTPRetryPolicy {
  public typealias ProcessURLResponse = @Sendable (HTTPURLResponse) -> StatusCodeProcessingResult

  public var backoffPolicy: BackoffPolicy
  public var maxRetries: Int
  public var processUrlResponse: ProcessURLResponse

  public init(
    backoffPolicy: BackoffPolicy,
    maxRetries: Int,
    processUrlResponse: @escaping ProcessURLResponse
  ) {
    self.backoffPolicy = backoffPolicy
    self.maxRetries = maxRetries
    self.processUrlResponse = processUrlResponse
  }

  public func process(
    error: any Error,
    requestsCount: Int
  ) -> HTTPRetryPolicyProcessingResultFailure {
    let error = error as NSError
    return if error.domain == NSURLErrorDomain, error.code == URLError.timedOut.rawValue {
      makeRetry(requestsCount: requestsCount)
    } else {
      .noRetry
    }
  }

  public func process(
    urlResponse: HTTPURLResponse,
    requestsCount: Int
  ) -> HTTPRetryPolicyProcessingResult {
    switch processUrlResponse(urlResponse) {
    case .success: .success
    case .failure: .failure(.noRetry)
    case .retry: .failure(makeRetry(requestsCount: requestsCount))
    }
  }

  private func makeRetry(requestsCount: Int) -> HTTPRetryPolicyProcessingResultFailure {
    requestsCount <= maxRetries
      ? .retry(backoffPolicy.nextTimeout(failedRequests: requestsCount))
      : .retryLimitReached
  }
}

// MARK: - DefaultHTTPRetryPolicy.StatusCodeProcessingResult

extension DefaultHTTPRetryPolicy {
  public enum StatusCodeProcessingResult {
    case success
    case retry
    case failure
  }
}
