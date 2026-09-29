// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreGeneral
import Testing

struct PartiallyKnownEnumTests {
  @Test func int() throws {
    let implicitB = MyEnumInt(rawValue: 1)

    #expect(implicitB == .known(.b))

    #expect(MyEnumInt.known(.a) < .known(.b))
    #expect(implicitB > .known(.a))
    #expect(implicitB < .known(.c))
  }

  @Test func string() throws {
    let implicitBaz = MyEnumString(rawValue: "baz")

    #expect(implicitBaz == .known(.baz))
    #expect(implicitBaz.rawValue > "bax")
    #expect(implicitBaz.rawValue == implicitBaz.description)
  }
}

// MARK: - MyEnumInt

private typealias MyEnumInt = PartiallyKnown<MyEnumIntKnown>

private enum MyEnumIntKnown: Int, Comparable {
  case a
  case b
  case c
  case d

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - MyEnumString

private typealias MyEnumString = PartiallyKnown<MyEnumStringKnown>

private enum MyEnumStringKnown: String, CustomStringConvertible, Equatable {
  case foo
  case bar
  case baz

  var description: String { rawValue }
}
