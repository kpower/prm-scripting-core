// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreInterpolation

public enum JSONValue: Codable, Equatable, Sendable {
  indirect case array([JSONValue])
  case bool(Bool)
  case null
  case number(JSONNumber)
  indirect case object([String:JSONValue])
  case string(String)

  public init(from decoder: Decoder) throws {
    if let atom = Self(singleValueFrom: decoder) {
      self = atom
    } else if let array = try? [JSONValue](from: decoder) {
      self = .array(array)
    } else if let obj = try? [String:JSONValue](from: decoder) {
      self = .object(obj)
    } else {
      throw DecodingError
        .dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown json type"))
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case let .array(array):
      try array.encode(to: encoder)
    case let .bool(bool):
      var container = encoder.singleValueContainer()
      try container.encode(bool)
    case .null:
      var container = encoder.singleValueContainer()
      try container.encodeNil()
    case let .number(number):
      try number.encode(to: encoder)
    case let .object(object):
      try object.encode(to: encoder)
    case let .string(string):
      var container = encoder.singleValueContainer()
      try container.encode(string)
    }
  }

  // MARK: - Private

  private init?(singleValueFrom decoder: Decoder) {
    if let number = try? JSONNumber(from: decoder) {
      self = .number(number)
      return
    }
    guard let container = try? decoder.singleValueContainer() else { return nil }

    if container.decodeNil() {
      self = .null
    } else if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let string = try? container.decode(String.self) {
      self = .string(string)
    } else {
      return nil
    }
  }
}

// MARK: - :CustomStringConvertible

extension JSONValue: CustomStringConvertible {
  public var description: String { indentedDescription() }

  func indentedDescription(childIndent: String = " ", quotedKeys: Bool = false, sortKeys: Bool = true) -> String {
    switch self {
    case let .bool(value):    "\(value)"
    case let .number(num):    "\(num)"
    case let .string(string): string.prm_wrapped(both: #"""#)
    case .null:               "null"
    case let .array(array):
      """
      [
      \(childIndent)\(prm_flattenInLines: array, quoted: quotedKeys, glue: childIndent)
      ]
      """
    case let .object(obj):
      """
      {
      \(childIndent)\(prm_flattenInLines: obj, quoted: quotedKeys, glue: childIndent)
      }
      """

    }
  }
}

// MARK: - Factories

extension JSONValue {
  public static func number(int value: some BinaryInteger & Sendable & Encodable) -> Self {
    .number(JSONNumber(int: value))
  }

  public static func number(float value: some BinaryFloatingPoint & Sendable & Encodable) -> Self {
    .number(JSONNumber(float: value))
  }
}

// MARK: - ExpressibleBy...Literal

extension JSONValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, JSONValue)...) {
    self = .object(Dictionary(elements, uniquingKeysWith: { $1 }))
  }
}

extension JSONValue: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: JSONValue...) {
    self = .array(elements)
  }
}

extension JSONValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: FloatLiteralType) {
    self = .number(JSONNumber(float: value))
  }
}

extension JSONValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: IntegerLiteralType) {
    self = .number(JSONNumber(int: value))
  }
}

extension JSONValue: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .null
  }
}

extension JSONValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}
