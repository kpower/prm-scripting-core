// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
  /// There is no `data(for:)` or `download(for:)` in FoundationNetworking (on Linux), so use completion-based methods.
  /// See details: https://github.com/apple/swift-corelibs-foundation/issues/3205
  func asyncTask<Payload>(
    request: URLRequest,
    dataPayloadFormatter: DataPayloadFormatter,
    delegate: URLSessionTaskDelegate?,
    taskFactory: (
      URLRequest,
      @escaping @Sendable (Payload?, URLResponse?, Error?) -> Void
    ) -> URLSessionTask
  ) async throws -> Response<Payload, URLResponse> {
    try await withCheckedThrowingContinuation { continuation in
      let task = taskFactory(request) { payload, urlResponse, error in
        if let error {
          return continuation.resume(throwing: error)
        }
        guard let urlResponse else {
          return continuation.resume(throwing: UrlResponseError.noResponseAndError(request))
        }
        guard let payload else {
          return continuation.resume(throwing: UrlResponseError.noPayload(urlResponse))
        }
        
        let response = Response(
          payload: payload,
          urlResponse: urlResponse,
          dataPayloadFormatter: dataPayloadFormatter
        )
        continuation.resume(returning: response)
      }
      task.delegate = delegate
      task.resume()
    }
  }
}

// MARK: - UrlResponseError

private enum UrlResponseError: Error {
  case noResponseAndError(URLRequest)
  case noPayload(URLResponse)
}
