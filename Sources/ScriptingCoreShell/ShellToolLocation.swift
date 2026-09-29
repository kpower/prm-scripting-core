// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation

public enum ShellToolLocation {
  case bin
  case usrBin

  func fileUrl(toolName: String) -> URL {
    URL(filePath: containerDirectory + toolName, directoryHint: .notDirectory)
  }

  private var containerDirectory: String {
    switch self {
    case .bin: "/bin/"
    case .usrBin: "/usr/bin/"
    }
  }
}
