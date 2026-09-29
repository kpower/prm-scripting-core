// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct RequestEndpoint: CustomStringConvertible, Sendable {
  public var scheme: Scheme
  public var host: String
  public var path: String
  public var queryItems: [QueryItem]?
  public var fragment: String?

  public var description: String {
    "\(scheme)://\(host)\(path)\(queryString)\(fragmentString)"
  }

  public init(
    scheme: Scheme = .https,
    host: String,
    path: String,
    queryItems: [QueryItem]? = nil,
    fragment: String? = nil
  ) {
    self.scheme = scheme
    self.host = host
    self.path = path
    self.queryItems = queryItems
    self.fragment = fragment
  }

  public init(url: URL, resolvingAgainstBaseURL resolve: Bool = true) throws {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: resolve),
          let scheme = components.scheme.flatMap(RequestEndpoint.Scheme.init(rawValue:)),
          let host = components.host
    else {
      throw RequestEndpointError.cantParseUrlComponents(url)
    }

    self.scheme = scheme
    self.host = host
    path = components.path
    queryItems = components.queryItems?.map {
      .queryItem(name: $0.name, $0.value ?? "")
    }
    fragment = components.fragment
  }

  public func url() throws -> URL {
    let components = urlComponents
    guard let url = components.url else {
      throw RequestEndpointError.cantCreateUrl(components)
    }
    return url
  }

  public func appendingQueryItems(_ additionalQueryItems: [QueryItem]) -> Self {
    Self(
      scheme: scheme,
      host: host,
      path: path,
      queryItems: (queryItems ?? []) + additionalQueryItems,
      fragment: fragment
    )
  }

  // MARK: - Private

  private var fragmentString: String {
    guard let fragment else { return "" }
    return "#" + fragment
  }

  private var queryString: String {
    guard let queryItems else { return "" }
    return "?" + queryItems.map(\.description).joined(separator: "&")
  }

  private var urlComponents: URLComponents {
    var components = URLComponents()
    components.scheme = scheme.rawValue
    components.host = host
    components.path = path
    components.queryItems = queryItems?.map(\.urlQueryItem)
    components.fragment = fragment
    return components
  }
}

// MARK: - URLRequestFactoryError

private enum RequestEndpointError: Error {
  case cantCreateUrl(URLComponents)
  case cantParseUrlComponents(URL)
}
