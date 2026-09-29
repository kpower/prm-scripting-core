// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreGeneral
import ScriptingCoreInterpolation
import Testing

struct InterpolationTests {
  @Test func flattenDictionary() throws {
    let source = [
      "Test": 1,
      "Key": 2,
      "Value": 3
    ]

    let singleUnordered = "\(prm_flatten: source, quoted: true, glue: " | ", sortKeys: false)"
    try singleUnordered.expectConsistOfBlocks([ "'Test': '1'", "'Key': '2'", "'Value': '3'" ], separator: " | ")

    let singleOrdered = "\(prm_flatten: source, quoted: true, glue: " | ")"
    #expect(singleOrdered == "'Key': '2' | 'Test': '1' | 'Value': '3'")

    let multiUnordered = "-\(prm_flattenInLines: source, quoted: false, glue: "-", sortKeys: false)"
    try multiUnordered.expectConsistOfBlocks([ "-Key: 2", "-Test: 1", "-Value: 3", ], separator: "\n")
    try multiUnordered.expectConsistOfBlocks([ "-Test: 1", "-Key: 2", "-Value: 3", ], separator: "\n")

    let multiOrdered = "-\(prm_flattenInLines: source, quoted: false, glue: "-")"
    #expect(multiOrdered == """
      -Key: 2
      -Test: 1
      -Value: 3
      """)
  }

  @Test func flattenOther() throws {
    let source1 = [ 1, 2, 3 ]
    let single = "\(prm_flatten: source1)"
    #expect(single == "1, 2, 3")

    let multi = "-\(prm_flattenInLines: source1, glue: "-")"
    #expect(multi == """
      -1
      -2
      -3
      """)

    let singleUnordered = "\(prm_flatten: Set(source1), quoted: true, glue: " | ")"
    try singleUnordered.expectConsistOfBlocks([ "'1'", "'2'", "'3'" ], separator: " | ")
  }

  @Test func multiline() {
    let source = Node(
      val: "R",
      children: [
        Node(val: "R0", children: [ Node(val: "R00") ]),
        Node(val: "R1"),
        Node(val: "R2", children: [ Node(val: "R20"), Node(val: "R21") ]),
      ]
    )
    let single = "\(prm_multiline: source, glue: "-")"
    #expect(single == """
      R
      - R0
      -  R00
      - R1
      - R2
      -  R20
      -  R21
      """)
  }

  @Test func unwrap() {
    let val1: Int? = 14
    let unwrapped1 = "\(prm_unwrap: val1)"
    #expect(unwrapped1 == "14")

    let val2: Int? = nil
    let unwrapped2 = "\(prm_unwrap: val2)"
    #expect(unwrapped2 == "nil")
  }
}

// MARK: - Node

private struct Node: CustomStringConvertible {
  var val: String
  var children: [Node] = []

  var description: String {
    guard !children.isEmpty else { return val }
    return """
      \(val)
       \(prm_flattenInLines: children, glue: " ")
      """
  }
}

// MARK: -

extension String {
  /**
   * Check string is build using specified blocks, glued by separator. Each block should be used only once.
   *
   * - Throws: When string contains smth except blocks, or some block were unused / used twice
   */
  fileprivate func expectConsistOfBlocks(_ blocks: Set<String>, separator: String) throws {
    var i = startIndex
    var remainedBlocks = blocks
    while i < endIndex {
      let blockIndex = try #require(
        remainedBlocks.firstIndex {
          self[i...].hasPrefix($0)
        },
        "Unexpected block at \(self[i...])"
      )

      let block = remainedBlocks.remove(at: blockIndex)
      i = index(i, offsetBy: block.count)

      guard i < endIndex else { break }
      try #require(
        self[i...].hasPrefix(separator),
        "No separator at \(self[i...])"
      )
      i = index(i, offsetBy: separator.count)
    }

    try#require(
      remainedBlocks.isEmpty,
      "Unused blocks: \(remainedBlocks.joined(separator: ", "))"
    )
  }
}
