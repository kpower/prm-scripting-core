// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

extension Collection {
  /// Extract values that are duplicated by some key path (have same value)
  public func prm_duplicates<Value: Hashable>(keyPath: KeyPath<Element, Value>) -> [Value:[Element]] {
    reduce(into: [Value:[Element]](minimumCapacity: count)) { acc, item in
      let key = item[keyPath: keyPath]
      acc[key] = acc[key, default: []] + [ item ]
    }.filter { $0.value.count > 1 }
  }

  public func prm_single() throws -> Element {
    guard let first, count == 1 else {
      throw DescribedError("Single element expected, got \(self)")
    }
    return first
  }


  public func prm_singleOrNil() throws -> Element? {
    isEmpty ? nil : try prm_single()
  }
}

extension Collection where Element: Hashable {
  public var prm_duplicates: [Element] {
    var seen = Set<Element>()
    return filter { !seen.insert($0).inserted }
  }
}
