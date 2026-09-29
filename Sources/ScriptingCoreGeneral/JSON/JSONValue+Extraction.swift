// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

extension JSONValue {
  public func extractKeyPath(_ path: String...) throws -> JSONValue {
    try extractKeyPath(path)
  }

  public func extractKeyPath(_ path: [String]) throws -> JSONValue {
    try path.reduce(self) { node, key in
      let obj = try node.requireObject()
      guard let value = obj[key] else {
        throw DescribedError("Missing object value at '\(key)': \(self)")
      }
      return value
    }
  }

  public func extractKeyPathIfAvailable(_ path: String...) throws -> JSONValue? {
    try extractKeyPathIfAvailable(path)
  }

  public func extractKeyPathIfAvailable(_ path: [String]) throws -> JSONValue? {
    var node = self
    for key in path {
      let obj = try node.requireObject()
      guard let value = obj[key] else { return nil }
      node = value
    }
    return node
  }

  public func requireArray() throws -> [JSONValue] {
    switch self {
    case let .array(array): array
    case .bool, .null, .number, .object, .string:
      throw DescribedError("Array expected, got \(self)")
    }
  }

  public func requireArray(path: String...) throws -> [JSONValue] {
    try extractKeyPath(path).requireArray()
  }

  public func requireNumber() throws -> JSONNumber {
    switch self {
    case let .number(number): number
    case .array, .bool, .null, .object, .string:
      throw DescribedError("Number expected, got \(self)")
    }
  }

  public func requireNumber(path: String...) throws -> JSONNumber {
    try extractKeyPath(path).requireNumber()
  }

  public func requireNumberInt() throws -> Int {
    try requireNumber().requireInt()
  }

  public func requireNumberInt(path: String...) throws -> Int {
    try extractKeyPath(path).requireNumberInt()
  }

  public func requireNumberDouble() throws -> Double {
    try requireNumber().requireDouble()
  }

  public func requireNumberDouble(path: String...) throws -> Double {
    try extractKeyPath(path).requireNumberDouble()
  }

  public func requireObject() throws -> [String:JSONValue] {
    switch self {
    case let .object(obj): obj
    case .array, .bool, .null, .number, .string:
      throw DescribedError("Object expected, got \(self)")
    }
  }

  public func requireObject(path: String...) throws -> [String:JSONValue] {
    try extractKeyPath(path).requireObject()
  }

  public func requireString() throws -> String {
    switch self {
    case let .string(string): string
    case .array, .bool, .null, .number, .object:
      throw DescribedError("String expected, got \(self)")
    }
  }

  public func requireString(path: String...) throws -> String {
    try extractKeyPath(path).requireString()
  }
}
