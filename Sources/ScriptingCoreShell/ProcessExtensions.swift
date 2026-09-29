// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
import Synchronization

extension Process {
  static func runBash(
    tool: ShellTool,
    command: ShellCommand,
    onOutputChunk: @escaping @Sendable (Data) -> Void,
    onErrorChunk: @escaping @Sendable (Data) -> Void,
    waitRunLoop: RunLoop = .current,
  ) throws -> ShellResult {
    // setup
    let task = Process()
    task.arguments = [ "-c", command.toolCommand ]
    task.currentDirectoryURL = command.dir
    task.executableURL = tool.fileUrl
    task.standardInput = FileHandle.nullDevice

    // manage output and errors
    let error = PipeDataManager(onDataChunk: onErrorChunk)
    task.standardError = error.pipe

    let output = PipeDataManager(onDataChunk: onOutputChunk)
    task.standardOutput = output.pipe

    // process
    try task.run()

    // poll the run loop instead of `task.waitUntilExit()` to check with pipes reading finished
    var pipesWaitingUntil: Date?
    while task.isRunning || output.isReading || error.isReading {
      if !task.isRunning && pipesWaitingUntil == nil {
        pipesWaitingUntil = Date(timeIntervalSinceNow: handlersTimeout)
      }
      error.stop(after: pipesWaitingUntil)
      output.stop(after: pipesWaitingUntil)

      _ = waitRunLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
    }

    return ShellResult(
      command: command,
      terminationStatus: task.terminationStatus,
      output: output.storage.withLock { $0 },
      error: error.storage.withLock { $0 },
    )
  }
}

// MARK: - PipeDataManager

final class PipeDataManager: Sendable {
  let storage: Mutex<Data> = Mutex(Data())
  let pipe: Pipe = Pipe()

  var isReading: Bool {
    pipe.fileHandleForReading.readabilityHandler != nil
  }

  init(onDataChunk: @escaping @Sendable (Data) -> Void) {
    // weak to avoid a retain cycle pipe -> handler -> self when the handler is never reset
    pipe.setupReadByChunks { [weak self] data in
      self?.storage.withLock {
        $0.append(data)
      }
      onDataChunk(data)
    }
  }

  /// 1. When process writes more than fits into the pipe buffer, it would report termination faster than `readabilityHandler` gets all its data.
  /// So we need to ensure writing is over manually (by nullifying `readabilityHandler` in `setupReadByChunks`).
  ///
  /// 2. Task can be terminated without getting EOF even when some data was already read.
  /// Reproduced only on Linux with `ShellCommand("printf 'stdout failure\\n'; printf 'stderr failure\\n' >&2; exit 1")`
  /// So `readabilityHandler` won't be nullified ever.
  ///
  /// 3. To fix 1 + 2 we nullify it by some timeout.
  func stop(after stopDate: Date?) {
    if let stopDate, stopDate < .now {
      pipe.fileHandleForReading.readabilityHandler = nil
    }
  }
}

// MARK: -

extension Pipe {
  fileprivate func setupReadByChunks(_ onDataChunk: @escaping @Sendable (Data) -> Void) {
    fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if data.isEmpty {
        // EOF on the pipe
        handle.readabilityHandler = nil
      } else {
        onDataChunk(data)
      }
    }
  }
}

private let handlersTimeout: TimeInterval = 2
