// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
import ScriptingCoreGeneral
import Testing

struct JSONTests {
  @Test func extractNestedKeyPath() throws {
    let payload: JSONValue = [ "outer": [ "inner": [ "value": "found" ] ] ]

    #expect(try payload.extractKeyPath([ "outer", "inner", "value" ]) == .string("found"))
    #expect(try payload.requireString(path: "outer", "inner", "value") == "found")
    #expect(try payload.extractKeyPath("outer", "inner") == .object([ "value": .string("found") ]))
  }

  @Test func extractEmptyKeyPath() throws {
    let payload = JSONValue.string("value")

    #expect(try payload.extractKeyPath([]) == payload)
  }

  @Test func extractNullKeyPath() throws {
    let payload: JSONValue = [ "outer": [ "value": .null ] ]

    #expect(try payload.extractKeyPath("outer", "value") == .null)
  }

  @Test func extractMissingKeyPath() {
    let payload: JSONValue = [ "outer": [ "value": "found" ] ]

    #expect(throws: DescribedError.self) {
      try payload.extractKeyPath("outer", "missing")
    }
  }

  @Test func extractKeyPathThroughScalar() {
    let payload: JSONValue = [ "outer": "value" ]

    #expect(throws: DescribedError.self) {
      try payload.extractKeyPath("outer", "inner")
    }
  }

  @Test func decoding() async throws {
    let payload = try JSONDecoder().decode(JSONValue.self, from: testJSON.data(using: .utf8)!)

    let compared = JSONValue.object([
      "foo": [
        .number(int: 1),
        .bool(true),
        .bool(false),
        .string("1231"),
        .null,
        .number(float: 15.31),
        .number(float: 182),
        .object([
          "bar": .array([
            .number(int: 1),
            .number(float: 0),
            .number(float: 4.0),
          ]),
          "baz": .object([
            "a": .string("b"),
            "c": .null
          ]),
        ])
      ],
      "bar": [ .null, .null, .null, ],
    ])

    #expect(payload == compared)
  }

  @Test func description() async throws {
    let payload = try JSONDecoder().decode(JSONValue.self, from: testJSON.data(using: .utf8)!)

    let compared = """
      {
       bar: [
        null
        null
        null
       ]
       foo: [
        1
        true
        false
        "1231"
        null
        15.31
        182
        {
         bar: [
          1
          0
          4
         ]
         baz: {
          a: "b"
          c: null
         }
        }
       ]
      }
      """

    let payloadLines = payload.description.split(separator: "\n")
    let comparedLines = compared.split(separator: "\n")
    for (i, (payloadLine, compareLine)) in zip(payloadLines, comparedLines).enumerated() {
      #expect(payloadLine == compareLine, "at \(i)")
    }

    #expect(payload.description == compared)
  }

  private let testJSON = """
    {
      "foo": [
        1,
        true,
        false,
        "1231",
        null,
        15.31,
        182,
        {
          "baz": {
            "a": "b",
            "c": null
          },
          "bar": [ 1, 0, 4 ]
        } 
      ],
      "bar": [ null, null, null ]
    }
    """
}
