// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif

public struct RequestFactory: Sendable {
  public var globalHeaders: RequestHeaders

  public init(globalHeaders: RequestHeaders = RequestHeaders()) {
    self.globalHeaders = globalHeaders
  }

  public func makeUrlRequest(
    method: RequestMethod,
    endpoint: RequestEndpoint,
    headers: RequestHeaders = RequestHeaders()
  ) throws -> URLRequest {
    try makeUrlRequest(method: method, url: endpoint.url(), headers: headers)
  }

  public func makeUrlRequest(
    method: RequestMethod,
    url: URL,
    headers: RequestHeaders = RequestHeaders()
  ) throws -> URLRequest {
    var request = URLRequest(url: url)
    request.setHeaders(globalHeaders)
    request.setHeaders(headers)

    request.httpBody = try method.httpBody()
    request.httpMethod = method.httpMethod

    if let contentType = method.contentType {
      request.setValue(contentType.headerValue, forHTTPHeaderField: ContentType.headerName)
    }

    return request
  }
}

extension URLRequest {
  fileprivate mutating func setHeaders(_ headers: RequestHeaders) {
    for header in headers.contents {
      setValue(header.value, forHTTPHeaderField: header.key)
    }
  }
}
