// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

enum ContentType {
  case applicationJson
  case applicationXWwwFormUrlEncoded
  case multipartFormData(boundary: String)
  case textHtml(charset: String)

  static let headerName = "Content-Type"

  var headerValue: String {
    switch self {
    case .applicationJson: "application/json"
    case .applicationXWwwFormUrlEncoded: "application/x-www-form-urlencoded"
    case let .multipartFormData(boundary): "multipart/form-data; boundary=\(boundary)"
    case let .textHtml(charset): "text/html; charset=\(charset)"
    }
  }
}
