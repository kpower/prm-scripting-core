// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif
public import Logging
import ScriptingCoreGeneral
import ScriptingCoreInterpolation

// MARK: - RequestPerformer

public struct RequestPerformer: Sendable {
  public var dataPayloadFormatter: DataPayloadFormatter
  public var delegate: URLSessionTaskDelegate?
  public var httpRetryPolicy: HTTPRetryPolicy
  public var logger: Logger
  public var urlSession: URLSession

  public init(
    urlSession: URLSession,
    httpRetryPolicy: HTTPRetryPolicy,
    logger: Logger,
    dataPayloadFormatter: DataPayloadFormatter = .string,
    delegate: URLSessionTaskDelegate? = nil
  ) {
    self.dataPayloadFormatter = dataPayloadFormatter
    self.delegate = delegate
    self.httpRetryPolicy = httpRetryPolicy
    self.logger = logger
    self.urlSession = urlSession
  }

  public func asyncData(for request: URLRequest) async throws -> Response<Data, URLResponse> {
    try await urlSession.asyncTask(
      request: request,
      dataPayloadFormatter: dataPayloadFormatter,
      delegate: delegate,
      taskFactory: urlSession.dataTask(with:completionHandler:)
    )
  }

  public func asyncDownload(for request: URLRequest) async throws -> Response<URL, URLResponse> {
    try await urlSession.asyncTask(
      request: request,
      dataPayloadFormatter: dataPayloadFormatter,
      delegate: delegate,
      taskFactory: urlSession.downloadTask(with:completionHandler:)
    )
  }

  /// pass httpRetryPolicy to overwrite default one
  public func asyncHttpData(
    for request: URLRequest,
    httpRetryPolicy: HTTPRetryPolicy? = nil
  ) async throws -> Response<Data, HTTPURLResponse> {
    try await Self.asyncHttpTask(
      for: request,
      httpRetryPolicy: httpRetryPolicy ?? self.httpRetryPolicy,
      logger: logger,
      iteration: asyncData(for:)
    )
  }

  /// pass httpRetryPolicy to overwrite default one
  public func asyncHttpDownload(
    for request: URLRequest,
    httpRetryPolicy: HTTPRetryPolicy? = nil
  ) async throws -> Response<URL, HTTPURLResponse> {
    try await Self.asyncHttpTask(
      for: request,
      httpRetryPolicy: httpRetryPolicy ?? self.httpRetryPolicy,
      logger: logger,
      iteration: asyncDownload(for:)
    )
  }

  // MARK: - Private

  private static func asyncHttpTask<Payload>(
    for request: URLRequest,
    httpRetryPolicy: HTTPRetryPolicy,
    logger: Logger,
    iteration: @escaping (URLRequest) async throws -> Response<Payload, URLResponse>
  ) async throws -> Response<Payload, HTTPURLResponse> {
    let uuid = UUID()
    let start = Date().timeIntervalSince1970

    logger.debug("Request start", metadata: [
      "uuid": "\(uuid)",
      "request": "\(request)",
    ])

    for i in 1... {
      let onRetry = {
        logger.debug("Request failed", metadata: [
          "uuid": "\(uuid)",
          "retry": "#\(i + 1)",
        ])
      }

      let rawResponse: Response<Payload, URLResponse>
      do {
        rawResponse = try await iteration(request)
      } catch {
        try await httpRetryPolicy.process(error: error, requestsCount: i)
          .handleRequestFailure(
            onRetry: onRetry,
            errorFactory: {
              makeError(reason: $0, obj: error)
            }
          )
        continue
      }

      let response = try rawResponse.http(successStatusCodesOnly: false)
      switch httpRetryPolicy.process(urlResponse: response.urlResponse, requestsCount: i) {
      case .success:
        let delta = Date().timeIntervalSince1970 - start
        logger.debug("Request finished", metadata: [
          "uuid": "\(uuid)",
          "dt": "\(delta)",
        ])
        return response
      case let .failure(failure):
        try await failure.handleRequestFailure(
          onRetry: onRetry,
          errorFactory: {
            makeError(reason: $0, obj: response)
          }
        )
      }
    }
    throw DescribedError("[\(uuid)] Request failed \(request): retry overflow")
  }
}

// MARK: -

extension HTTPRetryPolicyProcessingResultFailure {
  fileprivate func handleRequestFailure(
    onRetry: () -> Void,
    errorFactory: (_ message: String) -> any Error
  ) async throws {
    switch self {
    case let .retry(duration):
      onRetry()
      try await Task.sleep(for: duration)
    case .retryLimitReached:
      throw errorFactory("Retry limit reached")
    case .noRetry:
      throw errorFactory("No retry expected")
    }
  }
}

fileprivate func makeError<T>(reason: String, obj: T) -> Error {
  DescribedError(reason + "\n  \(prm_multiline: obj, glue: "  ")")
}
