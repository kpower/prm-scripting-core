// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

/// JSON tells nothing about it's number type in context of Swift types. When you get digits without "." separator it doesn't mean it's integer -
/// it can also be so-written double. So you can't guess type - it was fixed on API level, get knowledge from there. So we hide real value and you should
/// extract it according to your expectations
public struct JSONNumber: CustomStringConvertible, Equatable, Sendable {
  var storage: JSONNumberStorage

  public var description: String {
    switch storage {
    case let .int(value): "\(value)"
    case let .float(value): "\(value)"
    }
  }

  public init(int value: some BinaryInteger & Sendable & Encodable) {
    storage = .int(value)
  }

  public init(float value: some BinaryFloatingPoint & Sendable & Encodable) {
    storage = .float(value)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try? container.decode(Int64.self) {
      self.init(int: value)
    } else if let value = try? container.decode(Double.self) {
      self.init(float: value)
    } else {
      throw DecodingError
        .dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown number type"))
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()

    switch storage {
    case let .int(value): try container.encode(value)
    case let .float(value): try container.encode(value)
    }
  }
}
