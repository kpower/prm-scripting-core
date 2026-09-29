// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Logging
import ScriptingCoreLogging
import Testing

struct NestedLoggerFactoryTests {
  @Test func nestedLabels() throws {
    let factory = Logger.prm_makeLogger(label: "some-label", logLevel: .debug)
      .prm_makeChildLogger(suffix: "test")
      .prm_makeChildLogger(suffix: "foo", glue: "_")
    #expect(factory.label == "some-label.test_foo")
    #expect(factory.logLevel == .debug)
  }

  @Test func nestedTypeLabels() throws {
    let factory = Logger.prm_makeLogger(of: Self.self, logLevel: .trace)
      .prm_makeChildLogger(of: Logger.self)
      .prm_makeChildLogger(of: Int.self, glue: "_")
    #expect(factory.label == "NestedLoggerFactoryTests.Logger_Int")
  }
}
