// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Synchronization

extension Sequence where Element: Sendable, Self: SendableMetatype {
  public func prm_asyncCompactMap<T: Sendable>(
    of _: T.Type = T.self,
    chunkSize: Int? = nil,
    progress: @escaping @Sendable (AsyncProgressInfo) async throws -> Void = { _ in },
    transform: @escaping @Sendable (AsyncTransformInfo<Element>) async throws -> T?,
  ) async rethrows -> [T] {
    try await prm_asyncMap(
      of: T?.self,
      chunkSize: chunkSize,
      progress: progress,
      transform: transform
    ).compactMap { $0 }
  }

  public func prm_asyncMap<T: Sendable>(
    of _: T.Type = T.self,
    chunkSize: Int? = nil,
    progress: @escaping @Sendable (AsyncProgressInfo) async throws -> Void = { _ in },
    transform: @escaping @Sendable (AsyncTransformInfo<Element>) async throws -> T,
  ) async rethrows -> [T] {
    try await withThrowingTaskGroup(of: (offset: Int, element: T).self) { group in
      let accumulator = Accumulator<T>()
      let count = count { _ in true }
      func addTask(element: Element) async {
        let index = accumulator.reserveItem() - 1

        group.addTask {
          let info = AsyncTransformInfo(offset: index, element: element)
          let result = try await transform(info)
          return (index, result)
        }
      }

      // plan initial chunk
      var iterator = makeIterator()
      for _ in 0..<(chunkSize ?? .max) {
        guard let next = iterator.next() else { break }
        await addTask(element: next)
      }

      // each finished task - plan new one
      while let taskResult = try await group.next() {
        let processed = accumulator.set(offset: taskResult.offset, value: taskResult.element)
        let info = AsyncProgressInfo(processed: processed, total: count)
        try await progress(info)

        guard let next = iterator.next() else { continue }
        await addTask(element: next)
      }

      let loaded = accumulator.loadedValues
      let total = accumulator.count
      precondition(loaded.count == total)
      precondition(count == total)

      return loaded
    }
  }
}

// MARK: - Accumulator

private struct Accumulator<T: Sendable>: ~Copyable {
  var loadedValues: [T] {
    contents.withLock {
      $0.compactMap(\.asLoaded)
    }
  }

  var count: Int {
    contents.withLock(\.count)
  }

  /// reserves item, returns total count
  func reserveItem() -> Int {
    contents.withLock {
      $0.append(.notLoaded)
      return $0.count
    }
  }

  /// set value at offset, returns progress (loaded values count)
  func set(offset: Int, value: T) -> Int {
    contents.withLock {
      $0[offset] = .loaded(value)
      return $0.compactMap(\.asLoaded).count
    }
  }

  // MARK: - Private

  private let contents = Mutex<[State]>([])

  private enum State: Sendable {
    case notLoaded
    case loaded(T)

    var asLoaded: T? {
      switch self {
      case .notLoaded: nil
      case let .loaded(value): value
      }
    }
  }
}
