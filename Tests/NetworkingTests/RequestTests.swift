// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import Foundation
@_spi(Testing) import ScriptingCoreNetworking
import Testing

struct RequestTests {
  @Test func endpoint() throws {
    let endpoint = RequestEndpoint(scheme: .https, host: "ya.ru", path: "/temp", queryItems: [
      .queryItem(name: "key_string", "value"),
      .queryItem(name: "key_int", 1),
      .queryItem(name: "key_bool", true)
    ])
    #expect(
      try endpoint.url().absoluteString == "https://ya.ru/temp?key_string=value&key_int=1&key_bool=true"
    )
  }

  @Test func headers() {
    var headers = RequestHeaders([
      "header0": "4",
      "header1": "1",
    ])
    var result = [ "header1": "1", "header0": "4" ]
    #expect(headers.contents == result)

    headers = headers.applyingBearerAuth(token: "bearer")
    result["Authorization"] = "Bearer bearer"
    #expect(headers.contents == result)

    headers = headers.applyingOAuth(token: "oauth1")
    result["Authorization"] = "OAuth oauth1"
    #expect(headers.contents == result)

    headers = headers.applyingOAuth(token: "oauth2", type: .team)
    result["Authorization"] = "OAuthTeam oauth2"
    #expect(headers.contents == result)
  }
}
