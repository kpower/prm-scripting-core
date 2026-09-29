// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation

extension String {
  public func prm_camelCaseToSnakeCase() -> Self {
    /// `AB` → `A_B`
    let acronymRegex = #/([A-Z]+)([A-Z][a-z]|[0-9])/#

    /// `aB` → `A_B`
    let normalRegex = #/([a-z0-9])([A-Z])/#

    return processCamelCaseRegex(acronymRegex)
      .processCamelCaseRegex(normalRegex)
      .lowercased()
  }

  /// `"a, b  , c,   d"` -> `["a", "b", "c", "d"]`
  public var prm_commaSeparatedArguments: [String] {
    split { "," == $0 }.map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  public func prm_minLength(_ length: Int, suffix: Character) -> Self {
    guard count < length else { return self }
    return self + Self(repeating: suffix, count: length - count)
  }

  /// `'text'`
  public var prm_apostrophed: Self {
    prm_wrapped(both: "'")
  }

  /// `(text)`
  public var prm_bracketed: Self {
    prm_wrapped(prefix: "(", suffix: ")")
  }

  /// `"text"`
  public var prm_quoted: Self {
    prm_wrapped(both: #"""#)
  }

  /// `[text]`
  public var prm_squareBracketed: Self {
    prm_wrapped(prefix: "[", suffix: "]")
  }

  /// `{both}text{both}`
  public func prm_wrapped(both: Self) -> Self {
    prm_wrapped(prefix: both, suffix: both)
  }

  /// `{prefix}text{suffix}`
  public func prm_wrapped(prefix: Self, suffix: Self) -> Self {
    prefix + self + suffix
  }

  // MARK: - Private

  private func processCamelCaseRegex(_ regex: Regex<(Substring, Substring, Substring)>) -> Self {
    replacing(regex, with: {
      "\($0.output.1)_\($0.output.2)".lowercased()
    })
  }
}

extension [[String]] {
  /// Align strings in table-like style (same-width columns).
  ///
  /// - Parameters:
  ///   - placeholder: character to enlarge string length
  ///   - appendPrefix: `true` to insert placeholder to string prefix (`false` - suffix)
  public func prm_alignCharacters(
    placeholder: Character,
    appendPrefix: @Sendable (_ row: Int, _ column: Int) -> Bool = { _, _ in true },
  ) -> Self {
    guard !isEmpty else { return self }

    let columns = reduce(0) { Swift.max($0, $1.count) }
    let widths = reduce(into: Array<Int>(repeating: 0, count: columns)) { widths, row in
      for (column, item) in row.enumerated() {
        widths[column] = Swift.max(widths[column], item.count)
      }
    }
    return enumerated().map { rowIdx, row in
      row.enumerated().map { colIdx, item in
        let diff = widths[colIdx] - item.count
        guard diff > 0 else { return item }

        let enlarger = String(repeating: placeholder, count: diff)
        return appendPrefix(rowIdx, colIdx) ? enlarger + item : item + enlarger
      }
    }
  }
}
