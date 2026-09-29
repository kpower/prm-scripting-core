# PrankMind ScriptingCore

A set of small Swift libraries for writing command-line tools and automation scripts: shell execution, HTTP requests with retries, JSON handling, console I/O, logging helpers and assorted standard-library extensions.

- Swift tools version: 6.4
- Platforms: macOS 15+, iOS 18+, Linux (tested in Docker, see below)
- License: Apache 2.0

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/kpower/prm-scripting-core.git", from: "0.1.0"),
],
targets: [
  .executableTarget(
    name: "MyTool",
    dependencies: [
      .product(name: "ScriptingCoreShell", package: "prm-scripting-core"),
      .product(name: "ScriptingCoreNetworking", package: "prm-scripting-core"),
    ]
  ),
]
```

Each library is a separate product, so you import only what you need.

## Libraries

| Library | Purpose |
|---|---|
| [ScriptingCoreGeneral](#scriptingcoregeneral) | Standard-library extensions, JSON model, errors |
| [ScriptingCoreInterpolation](#scriptingcoreinterpolation) | Readable string interpolation for collections, optionals, multi-line values |
| [ScriptingCoreAsyncSequence](#scriptingcoreasyncsequence) | Concurrent `map` / `compactMap` with chunking and progress |
| [ScriptingCoreConsole](#scriptingcoreconsole) | Console output with categories, reading user input |
| [ScriptingCoreLogging](#scriptingcorelogging) | `Logger` factory and child-logger helpers |
| [ScriptingCoreArgumentParser](#scriptingcoreargumentparser) | Reusable `--log-level` option |
| [ScriptingCoreShell](#scriptingcoreshell) | Run shell commands and capture output |
| [ScriptingCoreNetworking](#scriptingcorenetworking) | Build and perform HTTP requests with retry/backoff policies |

Members the package adds to standard and third-party types — extension methods and properties, and string-interpolation labels (`\(prm_flatten: ...)`) — are prefixed with `prm_`: an extension can't be disambiguated by module name, so the prefix avoids clashes with other packages. Types and global functions keep plain names; if one clashes with another module, qualify it (`ScriptingCoreGeneral.JSONValue`). Targets are built with the `InternalImportsByDefault` and `MemberImportVisibility` upcoming features, so extension members are visible only in files that import their module directly.

---

### ScriptingCoreGeneral

General-purpose helpers used by the other libraries.

- **`DescribedError`** — a simple `Error` carrying a human-readable description.
- **`modified(_:handle:)`** — returns a mutated copy of a value:
  `let request = modified(base) { $0.timeoutInterval = 30 }`
- **`PartiallyKnown<Known>`** — wraps a `RawRepresentable` enum so unknown raw values are kept (`.unknown(raw)`) instead of failing to decode. Conforms to `Equatable`, `Comparable`, `CustomStringConvertible`, `Sendable` when the wrapped type does.
- **JSON**
  - `JSONValue` — a `Codable` enum for arbitrary JSON (`array`, `bool`, `null`, `number`, `object`, `string`), expressible by literals.
  - `JSONNumber` — keeps integer and floating-point numbers distinct, because JSON itself doesn't tell you which one the API meant; extract with `requireInt()` / `requireDouble()`.
  - Extraction helpers: `extractKeyPath("a", "b")`, `extractKeyPathIfAvailable(...)`, `requireObject()`, `requireArray()`, `requireString()`, `requireNumberInt()`, `requireNumberDouble()` (all with `path:` variants). They throw `DescribedError` with the offending value on type mismatch.
- **`String`**
  - `prm_camelCaseToSnakeCase()` — `"parseURLValue"` → `"parse_url_value"`.
  - `prm_commaSeparatedArguments` — `"a, b  , c"` → `["a", "b", "c"]`.
  - `prm_minLength(_:suffix:)` — right-pad to a minimum length.
  - Wrapping: `prm_quoted`, `prm_apostrophed`, `prm_bracketed`, `prm_squareBracketed`, `prm_wrapped(both:)`, `prm_wrapped(prefix:suffix:)`.
- **`[[String]]`** — `prm_alignCharacters(placeholder:appendPrefix:)` pads cells so columns line up (table output).
- **`Sequence`** — `prm_sorted(by:_:_:)` sorts by up to three keys in priority order; `prm_groupedBy(\.keyPath)`.
- **`Collection`** — `prm_single()` / `prm_singleOrNil()` (throw when there's more than one element), `prm_duplicates` and `prm_duplicates(keyPath:)`.
- **`URL`** — `prm_pathReachable` (returns `PathExistence`: `.exist(isDirectory:)` or `.unavailable(Error)`), `prm_requireFile()`, `prm_requireDirectory()`, `prm_pathModificationDate`.

```swift
import ScriptingCoreGeneral

let json = try JSONDecoder().decode(JSONValue.self, from: data)
let name = try json.requireString(path: "user", "name")
let age  = try json.requireNumberInt(path: "user", "age")

try URL(filePath: "config.json").prm_requireFile()
```

### ScriptingCoreInterpolation

Extensions to `String.StringInterpolation` that produce readable output for logs and errors — without the long module paths `String(describing:)` prints for optionals and nested types.

| Interpolation | Result |
|---|---|
| `"\(prm_flatten: [1, 2, 3])"` | `1, 2, 3` |
| `"\(prm_flatten: dict, quoted: true)"` | `'a': '1', 'b': '2'` (keys sorted by default; pass `sortKeys: false` to keep order) |
| `"\(prm_flattenInLines: items, glue: "  ")"` | one element per line, following lines prefixed with `glue` |
| `"\(prm_multiline: value, glue: "  ")"` | indents every line after the first — handy for nesting descriptions |
| `"\(prm_unwrap: optional)"` / `"\(prm_unwrap: optional, defaults: "-")"` | the value, or `nil` / the default |
| `"\(prm_unwrapInLines: optional, glue: "  ")"` | same, for multi-line values |

### ScriptingCoreAsyncSequence

Concurrent transforms over any `Sequence` of `Sendable` elements, built on task groups. Results keep the original order.

```swift
import ScriptingCoreAsyncSequence

let pages = try await urls.prm_asyncMap(
  chunkSize: 4,                                   // at most 4 tasks in flight; nil = all at once
  progress: { print("\($0.processed)/\($0.total)") },
  transform: { info in try await download(info.element) }  // info.offset = index in source
)
```

`prm_asyncCompactMap` works the same way and drops `nil` results.

### ScriptingCoreConsole

Interactive console I/O that is independent of the log level.

- **`ConsoleInteractor`**
  - `out(_:params:)` — prints a message, prefixed with `[category]` when a category is set (defaults to `*` in DEBUG builds so console output is easy to filter from debug logs; empty in release).
  - `outEmptyLine()`, `makeNested(subcategory:)` (produces `parent.child` categories).
  - `readBool()` — asks `Y/n` until it gets a valid answer.
  - `readFormatted(prepare:beforeRead:transform:)` — generic prompt loop: normalises input, then repeats until `transform` returns non-nil.
- **`ConsoleOutParams`** — `terminator`, `trim`, `skipEmpty`; `.inline` prints without a newline.
- **`ConsoleStringTransform`** — chainable input normalisation: `.trim(.whitespacesAndNewlines).lowercase().modify { ... }`.

### ScriptingCoreLogging

Small helpers on top of [swift-log](https://github.com/apple/swift-log):

```swift
import ScriptingCoreLogging

let logger = Logger.prm_makeLogger(label: "my-tool", logLevel: .debug)
let child  = logger.prm_makeChildLogger(of: Downloader.self)  // label "my-tool.Downloader", same level
```

Also `Logger.prm_makeLogger(of: Type.self)` and `prm_makeChildLogger(suffix:glue:)`.

### ScriptingCoreArgumentParser

Reusable [swift-argument-parser](https://github.com/apple/swift-argument-parser) option groups.

- **`LoggingOptions`** — adds `--log-level <trace|debug|info|notice|warning|error|critical>` (default `info`) and exposes it as a `Logger.Level`.

```swift
import ArgumentParser
import ScriptingCoreArgumentParser

@main
struct Tool: AsyncParsableCommand {
  @OptionGroup var logging: LoggingOptions

  func run() async throws {
    let logger = Logger.prm_makeLogger(label: "tool", logLevel: logging.logLevel)
  }
}
```

### ScriptingCoreShell

Runs commands through `bash` or `zsh` (`-c "<command>"`) and captures stdout/stderr without pipe-buffer deadlocks.

- **`Shell(logger:tool:)`** — `perform(command:)` executes and returns a `ShellResult`; logs the command at `debug` and the result at `debug`/`error`.
- **`ShellCommand(_:dir:throwOnFailure:)`** — command string, optional working directory, and whether a non-zero exit status throws (default `true`).
- **`ShellResult`** — `output` and `error` as `Data`, `terminationStatus`, `isSuccess`.
- **`ShellTool`** — `.bash`, `.zsh`, or `.autodetected` (from `$SHELL`, falling back to bash).

```swift
import ScriptingCoreShell

let shell = Shell(logger: logger)
let result = try shell.perform(command: ShellCommand("git rev-parse HEAD", dir: repoURL))
let sha = String(decoding: result.output, as: UTF8.self)
```

### ScriptingCoreNetworking

A thin layer over `URLSession` for building requests and performing them with retries. Works on Linux via `FoundationNetworking` (uses completion-handler APIs internally, since async `data(for:)` isn't available there).

**Building requests**

- `RequestEndpoint` — scheme, host, path, query items, fragment; `url()`, `appendingQueryItems(_:)`, `init(url:)`.
- `RequestEndpointFactory` — shared scheme/host/path prefix/common query items; `makeEndpoint(pathSuffix:queryItems:fragment:)` (nil query items are skipped).
- `RequestEndpoint.QueryItem` — `.queryItem(name:_:)` for `String`, integers and `Bool`; `filter(included:)` for optional items; `extractQueryItems(urlString:)`.
- `RequestMethod` — `.get`, `.delete`, `.post(Post)`, where `Post` is `.idle`, `.json(Encodable, encoder:)`, `.text(String)`, `.formXWwwUrlEncoded(String)` or `.formMultipart(Data, boundary:)`. The matching `Content-Type` is set automatically.
- `RequestHeaders` — `modifying(name:value:)`, `applyingBearerAuth(token:)`, `applyingOAuth(token:type:)` (`OAuthTokenType.general` → `OAuth`, `.team` → `OAuthTeam`).
- `RequestFactory(globalHeaders:)` — `makeUrlRequest(method:endpoint:headers:)` merges global and per-request headers into a `URLRequest`.

**Performing requests**

- `RequestPerformer(urlSession:httpRetryPolicy:logger:dataPayloadFormatter:delegate:)`
  - `asyncData(for:)`, `asyncDownload(for:)` — single attempt, any response.
  - `asyncHttpData(for:httpRetryPolicy:)`, `asyncHttpDownload(for:httpRetryPolicy:)` — HTTP only, retried according to the policy.
- `Response<Payload, RawResponse>` — payload plus `URLResponse`; `.http()` casts to `HTTPURLResponse` and checks for a 2xx status, `.json(of:)` decodes a `Data` payload. Errors include the full response description.
- `DataPayloadFormatter` — how `Data` payloads appear in descriptions: `.string` (UTF-8 text) or `.count`.
- `HTTPStatusCodeGroup` — `informational`, `successful`, `redirection`, `clientError`, `serverError` with their status ranges.

**Retries and backoff**

- `HTTPRetryPolicy` protocol and `DefaultHTTPRetryPolicy` — retries URL timeouts and, by default, 5xx responses; 2xx is success, everything else fails immediately. Customise with `processUrlResponse`.
- `BackoffPolicy` implementations: `ConstBackoffPolicy`, `LinearBackoffPolicy`, `ExponentialBackoffPolicy` (equal jitter, per the [AWS backoff article](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)).
- `HTTPRetryPolicyFactory.makeDefaultHttpRetryPolicy(backoffType:latency:)` with presets:

| Latency | Max retries | Delay cap | Const | Linear step | Exponential base |
|---|---|---|---|---|---|
| `.short` | 10 | 30 s | 3 s | 1 s | 1 s |
| `.medium` | 15 | 120 s | 5 s | 5 s | 3 s |
| `.long` | 20 | 300 s | 10 s | 10 s | 10 s |

```swift
import ScriptingCoreNetworking

let endpoints = RequestEndpointFactory(host: "api.example.com", pathPrefix: "/v1")
let requests  = RequestFactory(globalHeaders: RequestHeaders().applyingBearerAuth(token: token))
let performer = RequestPerformer(
  urlSession: .shared,
  httpRetryPolicy: HTTPRetryPolicyFactory.makeDefaultHttpRetryPolicy(backoffType: .exponential, latency: .short),
  logger: logger
)

let request = try requests.makeUrlRequest(
  method: .get,
  endpoint: endpoints.makeEndpoint(pathSuffix: "/users", queryItems: [.queryItem(name: "limit", 50)])
)
let users = try await performer.asyncHttpData(for: request).json(of: [User].self).payload
```

---

## Development

### Running tests on macOS

```sh
swift build
swift test
```

### Running tests on Linux (Docker)

The package is also verified on Linux, where Foundation differs from Apple platforms (for example, networking lives in `FoundationNetworking`). `Dockerfile` builds the package in the official `swift` image and runs the test suite; `test-on-linux.sh` wraps the whole cycle.

#### 1. Install Docker with Homebrew and Colima

[Colima](https://github.com/abiosoft/colima) provides the Docker runtime (a lightweight Linux VM), and the Homebrew `docker` formula provides the CLI — Docker Desktop isn't needed.

```sh
# Homebrew itself, if it isn't installed yet: https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Container runtime, Docker CLI and the buildx plugin (test-on-linux.sh uses `docker buildx`)
brew install colima docker docker-buildx
```

Let the Docker CLI find the Homebrew-installed buildx plugin by adding this to `~/.docker/config.json` (create the file if it doesn't exist; on Intel Macs use `/usr/local` instead of `/opt/homebrew`):

```json
{
  "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
}
```

#### 2. Start Colima

```sh
# Swift compilation is memory-hungry, so give the VM some headroom
colima start --cpu 4 --memory 8 --disk 60
```

On Apple Silicon the VM is `arm64`, which matches the `linux/arm64` platform the test script uses, so no emulation is involved. On an Intel Mac, start an `aarch64` VM instead (slower, emulated): `colima start --arch aarch64 --cpu 4 --memory 8`.

Colima creates and activates a `colima` Docker context. Check that everything is wired up:

```sh
docker context ls        # `colima` should be marked with *
docker version           # shows both Client and Server
docker buildx version
```

To start Colima automatically at login: `brew services start colima`. To stop it: `colima stop`.

#### 3. Run the tests

```sh
./test-on-linux.sh
```

The script builds a temporary `linux/arm64` image (running `swift build -c release`), runs `swift test -c release` in a container, then deletes the image.

To do it by hand:

```sh
docker buildx build --platform linux/arm64 . -t scripting-core-tests --load
docker run --rm -it --platform linux/arm64 scripting-core-tests
docker image rm scripting-core-tests
```

#### Troubleshooting

- **`Cannot connect to the Docker daemon`** — Colima isn't running (`colima status`, then `colima start`), or another context is active (`docker context use colima`).
- **`docker: 'buildx' is not a docker command`** — the `cliPluginsExtraDirs` entry is missing or points to the wrong Homebrew prefix (`brew --prefix` shows the right one).
- **Compiler killed / `signal 9` during build** — the VM ran out of memory; restart it with more: `colima stop && colima start --memory 12`.
- **`package requires minimum Swift tools version`** — the `swift:` image tag in `Dockerfile` is older than the `swift-tools-version` in `Package.swift`; bump the image tag.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
