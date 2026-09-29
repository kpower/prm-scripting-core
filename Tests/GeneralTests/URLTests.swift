// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
import ScriptingCoreGeneral
import Testing

struct URLTests {
  @Test(arguments: [ false, true ])
  func requireFileAcceptsFile(allowUnavailable: Bool) throws {
    try withTemporaryDirectory { directory in
      let file = directory.appending(path: "script.py")
      try Data().write(to: file)

      try file.prm_requireFile(allowUnavailable: allowUnavailable)
      try file.prm_requireFile()
    }
  }

  @Test(arguments: [ false, true ])
  func requireFileRejectsDirectory(allowUnavailable: Bool) throws {
    try withTemporaryDirectory { directory in
      let directoryWithFileHint = URL(filePath: directory.path(), directoryHint: .notDirectory)
      #expect(throws: DescribedError.self) {
        try directoryWithFileHint.prm_requireFile(allowUnavailable: allowUnavailable)
      }
    }
  }

  @Test(arguments: [ false, true ])
  func requireDirectoryAcceptsDirectory(allowUnavailable: Bool) throws {
    try withTemporaryDirectory { directory in
      let directoryWithFileHint = URL(filePath: directory.path(), directoryHint: .notDirectory)
      try directoryWithFileHint.prm_requireDirectory(allowUnavailable: allowUnavailable)
      try directoryWithFileHint.prm_requireDirectory()
    }
  }

  @Test(arguments: [ false, true ])
  func requireDirectoryRejectsFile(allowUnavailable: Bool) throws {
    try withTemporaryDirectory { directory in
      let file = directory.appending(path: "script.py")
      try Data().write(to: file)
      #expect(throws: DescribedError.self) {
        try file.prm_requireDirectory(allowUnavailable: allowUnavailable)
      }
    }
  }

  @Test func unavailablePathsAreRejectedByDefault() throws {
    try withTemporaryDirectory { directory in
      let missingPath = directory.appending(path: "missing")
      #expect(throws: (any Error).self) { try missingPath.prm_requireFile() }
      #expect(throws: (any Error).self) { try missingPath.prm_requireDirectory() }
      #expect(throws: (any Error).self) { try missingPath.prm_requireFile(allowUnavailable: false) }
      #expect(throws: (any Error).self) { try missingPath.prm_requireDirectory(allowUnavailable: false) }
    }
  }

  @Test func unavailablePathsCanBeAllowed() throws {
    try withTemporaryDirectory { directory in
      let missingPath = directory.appending(path: "missing")
      try missingPath.prm_requireFile(allowUnavailable: true)
      try missingPath.prm_requireDirectory(allowUnavailable: true)
    }
  }
}

private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
  let fileManager = FileManager.default
  let directory = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
  try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
  defer {
    do {
      try fileManager.removeItem(at: directory)
      #expect(!fileManager.fileExists(atPath: directory.path()))
    } catch {
      Issue.record("Failed to remove temporary directory '\(directory.path())': \(error)")
    }
  }
  try body(directory)
}
