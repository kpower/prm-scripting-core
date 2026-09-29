// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif
import ScriptingCoreGeneral
import ScriptingCoreInterpolation

// MARK: - Response

public struct Response<Payload: Sendable, RawResponse: URLResponse>:
    CustomStringConvertible, Sendable {
  public var dataPayloadFormatter: DataPayloadFormatter
  public var payload: Payload
  public var urlResponse: RawResponse

  public init(
    payload: Payload,
    urlResponse: RawResponse,
    dataPayloadFormatter: DataPayloadFormatter
  ) {
    self.dataPayloadFormatter = dataPayloadFormatter
    self.payload = payload
    self.urlResponse = urlResponse
  }

  public var description: String {
    """
      Payload:
        \(prm_multiline: payloadDescription, glue: "  ")
      URLResponse:
        \(prm_multiline: urlResponse, glue: "  ")
      """
  }

  private var payloadDescription: String {
    if let payload = payload as? Data {
      dataPayloadFormatter.string(payload: payload)
    } else {
      "\(payload)"
    }
  }
}

// MARK: - HTTP mapper

extension Response where RawResponse == URLResponse {
  public func http(
    successStatusCodesOnly: Bool = true
  ) throws -> Response<Payload, HTTPURLResponse> {
    guard let urlResponse = urlResponse as? HTTPURLResponse else {
      throw makeError(reason: "Non http response")
    }
    
    let response = Response<Payload, HTTPURLResponse>(
      payload: payload,
      urlResponse: urlResponse,
      dataPayloadFormatter: dataPayloadFormatter
    )
    guard !successStatusCodesOnly || successStatusCodes.contains(urlResponse.statusCode) else {
      throw makeError(reason: "Wrong HTTP status code: expected \(successStatusCodes)")
    }
    return response
  }
}

// MARK: - JSON mapper

extension Response where Payload == Data {
  public func json<T: Decodable>(
    decoder: JSONDecoder = JSONDecoder(),
    of _: T.Type = T.self
  ) throws -> Response<T, RawResponse> {
    do {
      let decoded = try decoder.decode(T.self, from: payload)
      return Response<T, RawResponse>(
        payload: decoded,
        urlResponse: urlResponse,
        dataPayloadFormatter: dataPayloadFormatter
      )
    } catch {
      throw makeError(reason: "JSON parsing failed:\n  \(prm_multiline: error, glue: "  ")\n")
    }
  }
}

// MARK: -

extension Response {
  fileprivate func makeError(reason: String) -> Error {
    DescribedError(reason + "\n  \(prm_multiline: self, glue: "  ")")
  }
}

private let successStatusCodes = HTTPStatusCodeGroup.successful.statusCodes
