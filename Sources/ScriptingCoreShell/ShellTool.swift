// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public struct ShellTool: Sendable {
  /// fallback to bash as most common
  public static let autoSh = [ .zsh, .bash ].firstFromEnvironment() ?? .bash

  public static let bash = Self(toolName: "bash", location: .bin)
  public static let zsh = Self(toolName: "zsh", location: .bin)

  public var fileUrl: URL

  public init(fileUrl: URL) {
    self.fileUrl = fileUrl
  }

  public init(toolName: String, location: ShellToolLocation) {
    fileUrl = location.fileUrl(toolName: toolName)
  }
}

// MARK: -

extension [ShellTool] {
  fileprivate func firstFromEnvironment() -> Element? {
    guard let shellPath = ProcessInfo.processInfo.environment["SHELL"] else { return nil }

    return first {
      let toolName = $0.fileUrl.lastPathComponent
      return shellPath.hasSuffix("/" + toolName) || shellPath == toolName
    }
  }
}
