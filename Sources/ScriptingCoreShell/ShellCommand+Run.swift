// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation
public import Logging
import Synchronization

extension ShellCommand {
  /// Runs the command synchronously and collects its stdout and stderr.
  ///
  /// Blocks the caller while polling `waitRunLoop` until the process exits and both pipes are drained.
  ///
  /// - Parameters:
  ///   - logger: receives the command, output chunks (trace) and the final result.
  ///   - onOutputChunk: called with each stdout chunk as it arrives, on a background queue.
  ///   - onErrorChunk: called with each stderr chunk as it arrives, on a background queue.
  ///   - waitRunLoop: run loop polled while waiting for the process to finish.
  ///   - handlersTimeout: how long to keep reading pipes after the process exits before giving up on EOF.
  /// - Returns: the termination status with the full collected output and error data.
  /// - Throws: if the process fails to launch, or when it exits with a non-zero status and `throwOnFailure` is `true`.
  public func run(
    logger: Logger,
    onOutputChunk: @escaping @Sendable (Data) -> Void = { _ in },
    onErrorChunk: @escaping @Sendable (Data) -> Void = { _ in },
    waitRunLoop: RunLoop = .current,
    handlersTimeout: TimeInterval = 2,
  ) throws -> ShellResult {
    logger.debug("Execute shell command", metadata: [
      "command": .stringConvertible(self),
    ])

    let error  = PipeDataManager(logger: logger, chunkMessage: "error chunk", onDataChunk: onErrorChunk)
    let output = PipeDataManager(logger: logger, chunkMessage: "output chunk", onDataChunk: onOutputChunk)
    let process = makeProcess(errorPipe: error.pipe, outputPipe: output.pipe)

    try process.run()

    process.waitUntilExitAndReadFinished(
      waitRunLoop: waitRunLoop,
      handlersTimeout: handlersTimeout,
      pipeManagers: [ error, output ],
    )

    return try makeResult(
      process: process,
      error: error.storage.withLock { $0 },
      output: output.storage.withLock { $0 },
      logger: logger,
    )
  }

  // MARK: - Private

  private func makeProcess(errorPipe: Pipe, outputPipe: Pipe) -> Process {
    let process = Process()
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectoryURL
    process.executableURL = tool.executableURL
    process.standardError = errorPipe
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = outputPipe
    return process
  }

  private func makeResult(process: Process, error: Data, output: Data, logger: Logger) throws -> ShellResult {
    let result = ShellResult(
      command: self,
      terminationStatus: process.terminationStatus,
      output: output,
      error: error,
    )

    logger.log(level: result.isSuccess ? .debug : .error, "Shell command finished", metadata: [
      "result": .stringConvertible(result),
      "stdout": .string(result.output.utf8String),
      "stderr": .string(result.error.utf8String),
    ])
    guard result.isSuccess || !throwOnFailure else {
      throw ShellCommandError.failed(result)
    }
    return result
  }
}

// MARK: - PipeDataManager

final class PipeDataManager: Sendable {
  let storage: Mutex<Data> = Mutex(Data())
  let pipe: Pipe = Pipe()

  var isReading: Bool {
    pipe.fileHandleForReading.readabilityHandler != nil
  }

  init(logger: Logger, chunkMessage: Logger.Message, onDataChunk: @escaping @Sendable (Data) -> Void) {
    // weak to avoid a retain cycle pipe -> handler -> self when the handler is never reset
    pipe.setupReadByChunks { [weak self] data in
      logger.trace(chunkMessage, metadata: [
        "data": .string(data.utf8String),
      ])
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

// MARK: - ShellCommandError

private enum ShellCommandError: Error {
  case failed(ShellResult)
}

// MARK: -

extension Data {
  fileprivate var utf8String: String {
    String(decoding: self, as: UTF8.self)
  }
}

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

extension Process {
  /// poll the run loop instead of `waitUntilExit()` to check with pipes reading finished
  fileprivate func waitUntilExitAndReadFinished(
    waitRunLoop: RunLoop,
    handlersTimeout: TimeInterval,
    pipeManagers: [PipeDataManager],
  ) {
    var pipesWaitingUntil: Date?
    while isRunning || pipeManagers.contains(where: \.isReading) {
      if !isRunning && pipesWaitingUntil == nil {
        pipesWaitingUntil = Date(timeIntervalSinceNow: handlersTimeout)
      }

      for mngr in pipeManagers {
        mngr.stop(after: pipesWaitingUntil)
      }

      _ = waitRunLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
    }
  }
}
