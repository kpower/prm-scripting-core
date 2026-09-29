// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation

public enum ShellTool: CaseIterable, Sendable {
  case bash
  case zsh

  /// fallback to bash as most common
  public static let autodetected = detect() ?? .bash

  public var fileUrl: URL {
    URL(filePath: "/bin/" + toolName, directoryHint: .notDirectory)
  }

  private var toolName: String {
    switch self {
    case .bash: "bash"
    case .zsh:  "zsh"
    }
  }

  private static func detect() -> Self? {
    guard let shellPath = ProcessInfo.processInfo.environment["SHELL"] else { return nil }
    return allCases.first { shellPath.contains($0.toolName) }
  }
}
