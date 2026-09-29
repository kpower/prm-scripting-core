// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

extension URL {
  /// Require a file at the current path.
  /// - Parameter allowUnavailable: Whether to accept a missing or inaccessible path.
  /// - Throws: When the path points to a directory, or is unavailable and not allowed.
  public func prm_requireFile(allowUnavailable: Bool = false) throws {
    switch prm_pathReachable {
    case .exist(isDirectory: false):
      return
    case .exist(isDirectory: true):
      throw DescribedError("Expected a file at '\(path())', found a directory")
    case let .unavailable(error):
      guard allowUnavailable else { throw error }
    }
  }

  /// Require a directory at the current path.
  /// - Parameter allowUnavailable: Whether to accept a missing or inaccessible path.
  /// - Throws: When the path points to a file, or is unavailable and not allowed.
  public func prm_requireDirectory(allowUnavailable: Bool = false) throws {
    switch prm_pathReachable {
    case .exist(isDirectory: true):
      return
    case .exist(isDirectory: false):
      throw DescribedError("Expected a directory at '\(path())', found a file")
    case let .unavailable(error):
      guard allowUnavailable else { throw error }
    }
  }

  /// Check path exists and reachable (app can access it)
  public var prm_pathReachable: PathExistence {
    do {
      guard try checkResourceIsReachable() else {
        // should be unreachable - ObjC tells that returning NO passes Error with parameters
        return .unavailable(DescribedError("checkResourceIsReachable failed without specific error"))
      }

      return if let isDirectory = try isDirectoryResourceValue() {
        .exist(isDirectory: isDirectory)
      } else {
        // should be unreachable - we request flag value before fetching
        .unavailable(DescribedError("ResourceValue extration failed"))
      }
    } catch {
      return .unavailable(error)
    }
  }

  /// nil when access failed
  public var prm_pathModificationDate: Date? {
    try? resourceValues(forKeys: [ .contentModificationDateKey ]).contentModificationDate
  }

  private func isDirectoryResourceValue() throws -> Bool? {
    try resourceValues(forKeys: [ .isDirectoryKey ]).isDirectory
  }
}
