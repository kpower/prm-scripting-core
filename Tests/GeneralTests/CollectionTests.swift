// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreGeneral
import Testing

struct CollectionTests {
  @Test func single() throws {
    #expect(try [ 1 ].prm_single() == 1)
    #expect(throws: (any Error).self) {
      try ([] as [Int]).prm_single()
    }
    #expect(throws: (any Error).self) {
      try [ 1, 2 ].prm_single()
    }
  }

  @Test func singleOrNil() throws {
    #expect(try [ 1 ].prm_singleOrNil() == 1)
    #expect(try [Int]().prm_singleOrNil() == nil)
    #expect(throws: (any Error).self) {
      try [ 1, 2 ].prm_singleOrNil()
    }
  }
}
