// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public func modified<T: Copyable>(_ value: T, handle: (inout T) -> Void) -> T {
  var copy = value
  handle(&copy)
  return copy
}
