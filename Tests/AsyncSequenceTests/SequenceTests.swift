// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreAsyncSequence
import Testing

struct SequenceTests {
  @Test func asyncMap() async throws {
    let measurer = Measurer.unchunked()
    let source = [[1, 2], [3], [4, 5], [6], [7], [8, 9, 10]]

    let result = try await source.prm_asyncMap {
      try await measurer.process($0.element)
    }

    await measurer.expectFinished()
    #expect(source == result)
  }

  @Test func asyncMapOneByOne() async throws {
    let taken = LockActor()
    let progress = ValuesActor()
    let source = [[1, 2], [3], [4, 5], [6], [7], [8, 9, 10]]

    let result = try await source.prm_asyncMap(
      chunkSize: 1,
      progress: {
        await progress.append(value: $0.processed)
      },
      transform: {
        let locked = await taken.tryChange(to: true)
        #expect(locked)

        let local = try await process($0.element, sleepMs: defaultSleepMs)

        let unlocked = await taken.tryChange(to: false)
        #expect(unlocked)
        return local
      }
    )

    await progress.values.expectContinuity(starting: 1, finishing: source.count)
    #expect(source == result)
  }

  @Test func asyncMapChunked() async throws {
    let progress = ValuesActor()
    let measurer = Measurer.chunked()
    let source = [[1, 2], [3], [4, 5], [6], [7], [8, 9, 10]]

    let result = try await source.prm_asyncMap(
      chunkSize: measurer.chunkSize,
      progress: {
        await progress.append(value: $0.processed)
      },
      transform: {
        try await measurer.process($0.element)
      }
    )

    await measurer.expectFinished()
    #expect(source == result)

    let progressOrdered = await progress.values.sorted()
    progressOrdered.expectContinuity(starting: 1, finishing: source.count)
  }

  @Test func asyncCompactMap() async throws {
    let measurer = Measurer.unchunked()
    let source = [[1, 2], nil, [3], [4, 5], nil, [6], [7], [8, 9, 10]]

    let result = try await source.prm_asyncCompactMap {
      try await measurer.process($0.element)
    }

    await measurer.expectFinished()
    #expect(source.compactMap { $0 } == result)
  }

  @Test func asyncCompactMapOneByOne() async throws {
    let taken = LockActor()
    let progress = ValuesActor()
    let source = [[1, 2], nil, [3], [4, 5], nil, [6], [7], [8, 9, 10]]
    
    let result = try await source.prm_asyncCompactMap(
      chunkSize: 1,
      progress: {
        await progress.append(value: $0.processed)
      },
      transform: {
        let locked = await taken.tryChange(to: true)
        #expect(locked)

        let local = try await process($0.element, sleepMs: defaultSleepMs)

        let unlocked = await taken.tryChange(to: false)
        #expect(unlocked)
        return local
      }
    )

    await progress.values.expectContinuity(starting: 1, finishing: source.count)
    #expect(source.compactMap { $0 } == result)
  }

  @Test func asyncCompactMapChunked() async throws {
    let source = [[1, 2], nil, [3], [4, 5], nil, [6], [7], [8, 9, 10]]

    let progress = ValuesActor()
    let measurer = Measurer.chunked()
    let result = try await source.prm_asyncCompactMap(
      chunkSize: measurer.chunkSize,
      progress: {
        await progress.append(value: $0.processed)
      },
      transform: {
        try await measurer.process($0.element)
      }
    )

    await measurer.expectFinished()
    #expect(source.compactMap { $0 } == result)

    let progressOrdered = await progress.values.sorted()
    progressOrdered.expectContinuity(starting: 1, finishing: source.count)
  }
}

// MARK: - LockActor

private actor LockActor {
  func tryChange(to newLocked: Bool) -> Bool {
    guard locked != newLocked else { return false }
    locked = newLocked
    return true
  }

  private var locked = false
}

// MARK: - ValuesActor

private actor ValuesActor {
  private(set) var values: [Int] = []

  func append(value: Int) {
    values.append(value)
  }
}

// MARK: - Measurer

private actor Measurer {
  let chunkSize: Int?
  private let sleepMs: Int
  private(set) var maxTasksCount = 0
  private(set) var tasksCount = 0

  static func chunked(sleepMs: Int = defaultSleepMs, chunkSize: Int = defaultChunkSize) -> Self {
    Self(sleepMs: sleepMs, chunkSize: chunkSize)
  }

  static func unchunked(sleepMs: Int = defaultSleepMs) -> Self {
    Self(sleepMs: sleepMs, chunkSize: nil)
  }

  func process<T: Sendable>(_ param: T) async throws -> T {
    tasksCount += 1
    maxTasksCount = max(maxTasksCount, tasksCount)

    defer {
      precondition(tasksCount > 0)
      tasksCount -= 1
    }

    return try await AsyncSequenceTests.process(param, sleepMs: sleepMs)
  }

  func expectFinished(sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(tasksCount == 0, "Still have tasks", sourceLocation: sourceLocation)
    if let chunkSize {
      #expect(maxTasksCount == chunkSize, "Not all tasks in chunk used", sourceLocation: sourceLocation)
    } else {
      #expect(maxTasksCount > 1, "Only single chunk used while have no limit", sourceLocation: sourceLocation)
    }
  }

  private init(sleepMs: Int, chunkSize: Int?) {
    self.chunkSize = chunkSize
    self.sleepMs = sleepMs
  }
}

// MARK: -

extension [Int] {
  fileprivate func expectContinuity(
    starting: Int,
    finishing: Int,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(count == finishing - starting + 1, "Wrong count", sourceLocation: sourceLocation)
    #expect(first == starting, "Wrong start", sourceLocation: sourceLocation)
    #expect(last == finishing, "Wrong finish", sourceLocation: sourceLocation)

    for i in indices {
      #expect(
        self[i] == starting + i,
        "Wrong index at \(i): \(self)",
        sourceLocation: sourceLocation
      )
    }
  }
}

private func process<T: Sendable>(_ param: T, sleepMs: Int) async throws -> T {
  try await Task.sleep(for: .milliseconds(sleepMs))
  return param
}

private let defaultChunkSize = 2
private let defaultSleepMs = 3
