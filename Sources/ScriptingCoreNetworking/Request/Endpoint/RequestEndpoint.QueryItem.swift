// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation

extension RequestEndpoint {
  public struct QueryItem: CustomStringConvertible, Sendable {
    public var name: String
    public var value: String

    public var description: String {
      "\(name)=\(value)"
    }

    var urlQueryItem: URLQueryItem {
      URLQueryItem(name: name, value: value)
    }

    public init(name: String, value: String) {
      self.name = name
      self.value = value
    }

    public func filter(included: Bool) -> Self? {
      included ? self : nil
    }
  }
}

extension RequestEndpoint.QueryItem {
  /// extract query items from url string (or its part), returning all before `?` as prefix
  public static func extractQueryItems(urlString: String) -> (prefix: String, queryItems: [Self]) {
    let items = urlString.split(separator: "?", maxSplits: 1)

    let prefix = items.first ?? ""
    let queryItems: [RequestEndpoint.QueryItem] = items.count > 1
    ? items[1].split(separator: "&").compactMap {
      let kv = $0.split(separator: "=", maxSplits: 1)
      guard let key = kv.first else { return nil }
      let value = kv.count > 1 ? String(kv[1]) : ""
      return RequestEndpoint.QueryItem(name: String(key), value: value)
    }
    : []
    return (String(prefix), queryItems)
  }
}

extension RequestEndpoint.QueryItem {
  /// Same as the constructor, just syntax sugar to avoid `.init` or full-name creation
  public static func queryItem(name: String, _ value: String) -> Self {
    Self(name: name, value: value)
  }

  public static func queryItem(name: String, _ value: any BinaryInteger) -> Self {
    queryItem(name: name, "\(value)")
  }

  public static func queryItem(name: String, _ value: Bool) -> Self {
    queryItem(name: name, "\(value)")
  }
}
