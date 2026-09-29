// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public struct RequestEndpointFactory: Sendable {
  public var scheme: RequestEndpoint.Scheme
  public var host: String
  public var pathPrefix: String
  public var commonQueryItems: [RequestEndpoint.QueryItem]

  public init(
    scheme: RequestEndpoint.Scheme = .https,
    host: String,
    pathPrefix: String = "",
    commonQueryItems: [RequestEndpoint.QueryItem?] = []
  ) {
    self.scheme = scheme
    self.host = host
    self.pathPrefix = pathPrefix
    self.commonQueryItems = commonQueryItems.compactMap { $0 }
  }

  public func makeEndpoint(
    pathSuffix: String,
    queryItems: [RequestEndpoint.QueryItem?] = [],
    fragment: String? = nil
  ) -> RequestEndpoint {
    let queryItems = commonQueryItems + queryItems.compactMap { $0 }
    return RequestEndpoint(
      scheme: scheme,
      host: host,
      path: pathPrefix + pathSuffix,
      queryItems: queryItems.isEmpty ? nil : queryItems,
      fragment: fragment
    )
  }
}
