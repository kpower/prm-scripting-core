// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

extension RequestMethod {
  public enum Post: CustomStringConvertible {
    case idle
    case formMultipart(Data, boundary: String)
    case formXWwwUrlEncoded(String)
    case json(Encodable, encoder: JSONEncoder = JSONEncoder())
    case text(String)

    public var description: String {
      switch self {
      case .idle: ""
      case let .formMultipart(data, boundary):
        "<multipart/form-data boundary=\(boundary) count=\(data.count) />"
      case let .formXWwwUrlEncoded(payload):
        "<x-www-form-urlencoded \(payload.makePayloadXWwwFormUrlEncoded()) />"
      case let .json(payload, _):
        "<json \(payload) />"
      case let .text(payload):
        "<text \(payload) />"
      }
    }

    var contentType: ContentType? {
      switch self {
      case .idle: nil
      case .formXWwwUrlEncoded: .applicationXWwwFormUrlEncoded
      case let .formMultipart(_, boundary): .multipartFormData(boundary: boundary)
      case .json: .applicationJson
      case .text: .textHtml(charset: "utf-8")
      }
    }

    func httpBody() throws -> Data? {
      switch self {
      case .idle: nil
      case let .formXWwwUrlEncoded(content): try content.makeBodyXWwwFormUrlEncoded()
      case let .formMultipart(data, _): data
      case let .json(value, encoder): try encoder.encode(value)
      case let .text(payload): payload.data(using: .utf8)
      }
    }
  }
}

// MARK: - UrlRequestError

private enum RequestMethodError: Error {
  case noXWwwFormData(content: String)
}

// MARK: -

extension String {
  fileprivate func makeBodyXWwwFormUrlEncoded() throws -> Data {
    let payload = makePayloadXWwwFormUrlEncoded()
    guard let result = payload.data(using: .utf8) else {
      throw RequestMethodError.noXWwwFormData(content: payload)
    }
    return result
  }

  fileprivate func makePayloadXWwwFormUrlEncoded() -> Self {
    [
      "syntax": "plain",
      "text": xWwwFormUrlencoded(),
    ].map  { "\($0)=\($1)" }.joined(separator: "&")
  }

  private func xWwwFormUrlencoded(encodeSpace: Bool = true) -> Self {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "*-._")

    if !encodeSpace {
      allowed.insert(charactersIn: " ")
    }

    guard let encoded = addingPercentEncoding(withAllowedCharacters: allowed) else { return "" }
    return encodeSpace
      ? encoded.replacingOccurrences(of: " ", with: "+")
      : encoded
  }
}
