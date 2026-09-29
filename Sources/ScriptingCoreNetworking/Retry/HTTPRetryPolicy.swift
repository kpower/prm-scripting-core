// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif

// MARK: - HTTPRetryPolicy

public protocol HTTPRetryPolicy: Sendable {
  func process(error: Error, requestsCount: Int) -> HTTPRetryPolicyProcessingResultFailure
  func process(urlResponse: HTTPURLResponse, requestsCount: Int) -> HTTPRetryPolicyProcessingResult
}

// MARK: - HTTPRetryPolicyProcessingResult

public enum HTTPRetryPolicyProcessingResult {
  case success
  case failure(HTTPRetryPolicyProcessingResultFailure)
}

// MARK: - HTTPRetryPolicyProcessingResultFailure

public enum HTTPRetryPolicyProcessingResultFailure {
  case retry(Duration)
  case retryLimitReached
  case noRetry
}
