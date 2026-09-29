// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreGeneral
import Testing

struct SequenceTests {
  @Test func sortedArrayInt() {
    let source = [ 7, 4, 1, 0, 3 ].map(ValueWrapper.init(value:))
    let sorted = source.prm_sorted(by: \.value).map(\.value)
    #expect(sorted == [ 0, 1, 3, 4, 7 ])
  }

  @Test func sortedArrayString() {
    let source = [ "ad", "abas", "lala", "exp" ].map(ValueWrapper.init(value:))
    let sorted = source.prm_sorted(by: \.value).map(\.value)
    #expect(sorted == [ "abas", "ad", "exp", "lala" ])
  }

  @Test func sortedByOneKeyPreservesEqualKeys() {
    let sorted = Self.sortingSource.prm_sorted(by: \.first).map(\.id)
    #expect(sorted == [ "b", "c", "d", "e", "a" ])
  }

  @Test func sortedByTwoKeysPreservesEqualKeys() {
    let sorted = Self.sortingSource.prm_sorted(by: \.first, \.second).map(\.id)
    #expect(sorted == [ "c", "d", "e", "b", "a" ])
  }

  @Test func sortedByThreeKeysPreservesEqualKeys() {
    let sorted = Self.sortingSource.prm_sorted(by: \.first, \.second, \.third).map(\.id)
    #expect(sorted == [ "d", "e", "c", "b", "a" ])
  }

  private static let sortingSource: [(first: Int, second: Int, third: Int, id: String)] = [
    (2, 0, 0, "a"),
    (1, 2, 1, "b"),
    (1, 1, 2, "c"),
    (1, 1, 1, "d"),
    (1, 1, 1, "e"),
  ]

  @Test func sortedDictionaryIntString() {
    let source = [ 1: "1231", 14: "231321", 0: "22" ]
    let sorted = source.prm_sorted(by: \.key).map(DictionaryWrapper.init(key:value:))
    let checked = [ (0, "22"), (1, "1231"), (14, "231321") ].map(DictionaryWrapper.init(key:value:))

    #expect(sorted == checked)
  }

  @Test func sortedDictionaryStringInt() {
    let source = [ "ad": 121, "abas": 121, "pep": 0 ]
    let sorted = source.prm_sorted(by: \.key).map(DictionaryWrapper.init(key:value:))
    let checked = [ ("abas", 121), ("ad", 121), ("pep", 0) ].map(DictionaryWrapper.init(key:value:))

    #expect(sorted == checked)
  }

  @Test func groupedArrayByInt() throws {
    let source = [
      (7, "foo"),
      (4, "bar"),
      (4, "baz"),
      (4, "foo"),
      (7, "bar")
    ].map(ValuesWrapper.init(value1:value2:))

    let grouped = source.prm_groupedBy(\.value1)
    #expect(Set(grouped.keys) == [ 4, 7 ])

    let group0 = try #require(grouped[4])
    #expect(group0.allSatisfy { $0.value1 == 4 })
    #expect(group0.map(\.value2) == [ "bar", "baz", "foo" ])

    let group1 = try #require(grouped[7])
    #expect(group1.allSatisfy { $0.value1 == 7 })
    #expect(group1.map(\.value2) == [ "foo", "bar" ])
  }

  @Test func groupedArrayByString() throws {
    let source = [
      (7, "foo"),
      (4, "bar"),
      (4, "baz"),
      (4, "foo"),
      (7, "bar")
    ].map(ValuesWrapper.init(value1:value2:))

    let grouped = source.prm_groupedBy(\.value2)
    #expect(Set(grouped.keys) == [ "foo", "bar", "baz" ])

    let group = try #require(grouped["foo"])
    #expect(group.allSatisfy { $0.value2 == "foo" })
    #expect(group.map(\.value1) == [ 7, 4 ])

    let group0 = try #require(grouped["bar"])
    #expect(group0.allSatisfy { $0.value2 == "bar" })
    #expect(group0.map(\.value1) == [ 4, 7 ])

    let group1 = try #require(grouped["baz"])
    #expect(group1.allSatisfy { $0.value2 == "baz" })
    #expect(group1.map(\.value1) == [ 4 ])
  }
}

// MARK: - ValueWrapper

private struct ValueWrapper<T> {
  var value: T
}

// MARK: - DictionaryWrapper

private struct DictionaryWrapper<T, V>: Equatable where T: Equatable, V: Equatable {
  var key: T
  var value: V
}

// MARK: - ValuesWrapper

private struct ValuesWrapper<T, U> {
  var value1: T
  var value2: U
}
