// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

extension Sequence {
  public func prm_sorted(
    by transform0: @escaping (Element) -> some Comparable,
  ) -> [Element] {
    sorted(by: { lhs, rhs in
      areInIncreasingOrder(lhs, rhs, transform: transform0)
        ?? false
    })
  }

  public func prm_sorted(
    by transform0: @escaping (Element) -> some Comparable,
    _ transform1: @escaping (Element) -> some Comparable,
  ) -> [Element] {
    sorted(by: { lhs, rhs in
      areInIncreasingOrder(lhs, rhs, transform: transform0)
        ?? areInIncreasingOrder(lhs, rhs, transform: transform1)
        ?? false
    })
  }

  public func prm_sorted(
    by transform0: @escaping (Element) -> some Comparable,
    _ transform1: @escaping (Element) -> some Comparable,
    _ transform2: @escaping (Element) -> some Comparable,
  ) -> [Element] {
    sorted(by: { lhs, rhs in
      areInIncreasingOrder(lhs, rhs, transform: transform0)
        ?? areInIncreasingOrder(lhs, rhs, transform: transform1)
        ?? areInIncreasingOrder(lhs, rhs, transform: transform2)
        ?? false
    })
  }

  public func prm_groupedBy<T: Hashable>(_ keyPath: KeyPath<Element, T>) -> [T: [Element]] {
    reduce(into: [T: [Element]]()) { accumulator, element in
      let key = element[keyPath: keyPath]
      accumulator[key, default: [Element]()]
        .append(element)
    }
  }
}

private func areInIncreasingOrder<Root>(
  _ lhs: Root,
  _ rhs: Root,
  transform: (Root) -> some Comparable,
) -> Bool? {
  let lhs = transform(lhs)
  let rhs = transform(rhs)
  guard lhs != rhs else { return nil }

  return lhs < rhs
}
