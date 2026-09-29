// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Logging
import ScriptingCoreShell
import Synchronization
import Testing

struct ShellTests {
  @Test func capturesStandardOutputAndErrorSeparately() throws {
    let shell = Shell(logger: Logger(label: "ShellTests"))
    let result = try shell.perform(command: ShellCommand("printf stdout; printf stderr >&2"))

    #expect(result.terminationStatus == 0)
    #expect(String(decoding: result.output, as: UTF8.self) == "stdout")
    #expect(String(decoding: result.error, as: UTF8.self) == "stderr")
  }

  @Test func logsStandardOutputAndErrorBeforeThrowing() throws {
    let events = Mutex<[LogEvent]>([])
    let logger = Logger(label: "ShellTests") { _ in
      RecordingLogHandler { event in
        events.withLock { $0.append(event) }
      }
    }
    let shell = Shell(logger: logger)
    let command = ShellCommand("printf 'stdout failure\\n'; printf 'stderr failure\\n' >&2; exit 1")

    #expect(throws: (any Error).self) {
      try shell.perform(command: command)
    }

    let metadata = try #require(events.withLock { $0.last?.metadata })
    #expect(metadata["stdout"] == .string("stdout failure\n"))
    #expect(metadata["stderr"] == .string("stderr failure\n"))
  }
}

private struct RecordingLogHandler: LogHandler {
  var logLevel: Logger.Level = .trace
  var metadata: Logger.Metadata = [:]
  var onLog: @Sendable (LogEvent) -> Void

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  func log(event: LogEvent) {
    onLog(event)
  }
}
