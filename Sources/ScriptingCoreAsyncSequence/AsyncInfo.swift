// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

// MARK: - AsyncProgressInfo

public struct AsyncProgressInfo: Sendable {
  /// currently processed items count
  public var processed: Int
  /// total items count
  public var total: Int
}

// MARK: - AsyncTransformInfo

public struct AsyncTransformInfo<T: Sendable>: Sendable {
  /// offset in original sequence
  public var offset: Int
  /// currently processed element
  public var element: T
}
