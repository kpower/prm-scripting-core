// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

// There are some similar parameters in methods below. They were not generalized as structs to make
//  syntax less verbose on top level (in interpolation calls).

extension String.StringInterpolation {
  // MARK: - Single-line

  public mutating func appendInterpolation<K, V>(
    prm_flatten value: Dictionary<K, V>,
    quoted: Bool = false,
    glue: String = ", ",
  ) {
    appendInterpolation(value.flatten(quoted: quoted, sortKeys: true, glue: glue))
  }

  public mutating func appendInterpolation<K, V>(
    prm_flatten value: Dictionary<K, V>,
    quoted: Bool = false,
    glue: String = ", ",
    sortKeys: Bool,
  ) {
    appendInterpolation(value.flatten(quoted: quoted, sortKeys: sortKeys, glue: glue))
  }

  public mutating func appendInterpolation<S: Sequence>(
    prm_flatten value: S,
    quoted: Bool = false,
    glue: String = ", ",
  ) {
    appendInterpolation(value.flatten(quoted: quoted, glue: glue))
  }

  /// Avoid `String(describing:)` because it prints whole import path that is hard to read:
  ///  `Optional(module.ParentClass.(unknown context at $10f9f80fc).ChildClass)`
  public mutating func appendInterpolation<T>(
    prm_unwrap value: T?,
    defaults: String = "nil",
  ) {
    appendInterpolation(unwrap(value, defaults: defaults))
  }

  // MARK: - Multi-line

  /// - Parameters:
  ///   - glue:  next (except first) line prefix
  public mutating func appendInterpolation<K, V>(
    prm_flattenInLines value: [K: V],
    quoted: Bool = false,
    glue: String = "",
  ) {
    // glue - split - glue, otherwise you will fail on multiline flattening element
    appendInterpolation(prm_multiline: value.flatten(quoted: quoted, sortKeys: true, glue: linesSeparator), glue: glue)
  }

  /// - Parameters:
  ///   - glue:  next (except first) line prefix
  public mutating func appendInterpolation<K, V>(
    prm_flattenInLines value: [K: V],
    quoted: Bool = false,
    glue: String = "",
    sortKeys: Bool,
  ) {
    // glue - split - glue, otherwise you will fail on multiline flattening element
    appendInterpolation(prm_multiline: value.flatten(quoted: quoted, sortKeys: sortKeys, glue: linesSeparator), glue: glue)
  }

  /// - Parameters:
  ///   - glue:  next (except first) line prefix
  public mutating func appendInterpolation<S: Sequence>(
    prm_flattenInLines value: S,
    quoted: Bool = false,
    glue: String = "",
  ) {
    // glue - split - glue, otherwise you will fail on multiline flattening element
    appendInterpolation(prm_multiline: value.flatten(quoted: quoted, glue: linesSeparator), glue: glue)
  }

  /// - Parameters:
  ///   - glue:  next (except first) line prefix
  public mutating func appendInterpolation<T>(
    prm_multiline value: T,
    glue: String = "",
  ) {
    let source = "\(value)"
    let lines = source.split(separator: linesSeparator)

    appendInterpolation(lines.count > 1 ? lines.joined(separator: linesSeparator + glue) : source)
  }

  /// Avoid `String(describing:)` because it prints whole import path that is hard to read:
  ///  `Optional(module.ParentClass.(unknown context at $10f9f80fc).ChildClass)`
  ///
  /// - Parameters:
  ///   - glue:  next (except first) line prefix
  public mutating func appendInterpolation<T>(
    prm_unwrapInLines value: T?,
    defaults: String = "nil",
    glue: String = "",
  ) {
    appendInterpolation(prm_multiline: unwrap(value, defaults: defaults), glue: glue)
  }
}

// MARK: -

extension Sequence {
  fileprivate func flatten(quoted: Bool, glue: String) -> String {
    map { quoted ? "'\($0)'" : "\($0)" }.joined(separator: glue)
  }
}

extension Dictionary {
  fileprivate func flatten(quoted: Bool, sortKeys: Bool, glue: String) -> String {
    let raw = map { k, v in
      quoted ? "'\(k)': '\(v)'" : "\(k): \(v)"
    }
    let intermediate = sortKeys ? raw.sorted() : raw
    return intermediate.joined(separator: glue)
  }
}

private func unwrap<T>(_ value: T?, defaults: String) -> String {
  value.map { "\($0)" } ?? defaults
}

private let linesSeparator = "\n"
